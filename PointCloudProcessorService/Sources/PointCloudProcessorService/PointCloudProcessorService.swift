import Foundation
import Combine
import PointCloudRendererService
import Common

// Open3DPython
import Open3DSupport
import NumPySupport
import PythonSupport
import PythonKit
import LinkPython

public enum PointCloudProcessorServiceError: Error {
    case unknown
    case temporaryFile
    case pythonThreadState
}

public enum PointCloudProcessor {
    case statisticalOutlierRemoval(neighbors: Int, stdRatio: Double)
    case radiusOutlierRemoval(pointsCount: Int, radius: Double)
    case voxelDownSampling(voxelSize: Double)
}

final public class PointCloudProcessorService: ObservableObject {

    let o3d = Python.import("open3d")
    let numpy = Python.import("numpy")
    private var tstate: UnsafeMutableRawPointer?

    // Kept for Undo action
    @Published public var previousPointCloud: [ParticleUniforms]?

    public init() {}

    public func getPreviousPointCloudForUndo() -> [ParticleUniforms]? {
        guard let previousPointCloud = previousPointCloud else { return nil}
        let returnValue = previousPointCloud
        self.previousPointCloud = nil
        return returnValue
    }

    // MARK: - Open3D helpers

//    // Take a PLYFile as input for now (Partilcles + easy way to write them to disk as PLY)
//    public func voxelDownsampling(_ input: PLYFile) -> Future<[ParticleUniforms], PointCloudProcessorServiceError> {
//        Future { [weak self] promise in
//            guard let self = self else {
//                return promise(.failure(.unknown))
//            }
//
//            // Save for undo
//            self.previousPointCloud = input.particles
//
//            DispatchQueue.global(qos: .userInitiated).async {
//                // Generate TMP file
//                guard let plyFileURL = try? input.writeTemporaryFile() else {
//                    return promise(.failure(.temporaryFile))
//                }
//
//                // Pyton THREAD management stuff copied from Kewlbear programs
//                let gstate = PyGILState_Ensure()
//                defer {
//                    DispatchQueue.main.async {
//                        guard let tstate = self.tstate else {
//                            return promise(.failure(.pythonThreadState))
//                        }
//                        PyEval_RestoreThread(tstate)
//                        self.tstate = nil
//                    }
//                    PyGILState_Release(gstate)
//                }
//
//                // Start O3D processing
//                let pointCloud = self.o3d.io.read_point_cloud(plyFileURL.path)
//
//                let treatedParticles = convert(o3dPointCloud: pointCloud)
//                promise(.success(treatedParticles))
//            }
//
//            self.tstate = PyEval_SaveThread()
//        }
//    }

    public func process(_ input: PLYFile, with processors: [PointCloudProcessor]) -> Future<[ParticleUniforms], PointCloudProcessorServiceError> {
        Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.unknown))
            }

            // Save for undo
            DispatchQueue.main.async {
                self.previousPointCloud = input.particles
            }

            DispatchQueue.global(qos: .userInitiated).async {
                // Generate TMP file
                guard let plyFileURL = try? input.writeTemporaryFile() else {
                    return promise(.failure(.temporaryFile))
                }

                // Pyton THREAD management stuff copied from Kewlbear programs
                let gstate = PyGILState_Ensure()
                defer {
                    DispatchQueue.main.async {
                        guard let tstate = self.tstate else { fatalError() }
                        PyEval_RestoreThread(tstate)
                        self.tstate = nil
                    }
                    PyGILState_Release(gstate)
                }

                // Load PointCloud from TMP file into Open3D
                var pointCloud = self.o3d.io.read_point_cloud(plyFileURL.path)

                // Apply processors
                for processor in processors {
                    switch processor {
                    case let .voxelDownSampling(voxelSize):
                        pointCloud = self.o3dVoxelDownSampling(pointCloud, voxelSize: voxelSize)
                    case let .statisticalOutlierRemoval(neighbors, stdRatio):
                        pointCloud = self.o3dStatisticalOutlierRemoval(pointCloud, neighbors: neighbors, stdRatio: stdRatio)
                    case let .radiusOutlierRemoval(pointsCount, radius):
                        pointCloud = self.o3dRadiusOutlierRemoval(pointCloud, pointsCount: pointsCount, radius: radius)
                    }
                }

//                // Write changes to file
//                self.o3d.io.write_point_cloud(plyFileURL.path, pointCloud)

                // Convert Open3D PointCloud back to our Particles Uniform
                let treatedParticles = self.convertO3DBackToParticleUniforms(pointCloud)
                promise(.success(treatedParticles))
            }

            self.tstate = PyEval_SaveThread()
        }
    }

    private func convertO3DBackToParticleUniforms(_ o3dPointCloud: PythonObject) -> [ParticleUniforms] {
        let points = self.numpy.asarray(o3dPointCloud.points)
        let colors = self.numpy.asarray(o3dPointCloud.colors)

        return zip(points, colors).map { point, color in
            ParticleUniforms(position: Float3(Float(point[0])!, Float(point[1])!, Float(point[2])!),
                             color: Float3(Float(color[0])!, Float(color[1])!, Float(color[2])!), confidence: 1.0)
        }
    }

    // MARK: - Open3D point cloud processing methods

    private func o3dVoxelDownSampling(_ pointCloud: PythonObject, voxelSize: Double) -> PythonObject {
        pointCloud.voxel_down_sample(voxelSize)
        // Uniform downsample
        // let downSampledPointCloud = pointCloud.uniform_down_sample(5) // Every K points k == 5
    }

    /// statistical_outlier_removal removes points that are further away from their neighbors compared to the
    /// average for the point cloud
    /// - Parameters:
    ///   - pointCloud: The target
    ///   - neighbors: which specifies how many neighbors are taken into account in order to calculate the average distance
    ///   for a given point
    ///   - stdRatio: which allows setting the threshold level based on the standard deviation of the average distances
    ///    across the point cloud. The lower this number the more aggressive the filter will be.
    /// - Returns: inlierPointCloud
    private func o3dStatisticalOutlierRemoval(_ pointCloud: PythonObject, neighbors: Int, stdRatio: Double) -> PythonObject {
        pointCloud.remove_statistical_outlier(neighbors, stdRatio)[0]
        // pointCloud.select_by_index(result[1])
    }

    /// radius_outlier_removal removes points that have few neighbors in a given sphere around them
    /// - Parameters:
    ///   - pointCloud: The target
    ///   - pointsCount: lets you pick the minimum amount of points that the sphere should contain
    ///   - radius: defines the radius of the sphere that will be used for counting the neighbors.
    /// - Returns: inlierPointCloud
    private func o3dRadiusOutlierRemoval(_ pointCloud: PythonObject, pointsCount: Int, radius: Double) -> PythonObject {
        pointCloud.remove_radius_outlier(pointsCount, radius)[0]
        // pointCloud.select_by_index(result[1])
    }
}
