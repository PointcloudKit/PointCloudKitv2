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

public typealias O3DPointCloud = PythonObject
public typealias O3DTriangleMeshes = PythonObject
typealias O3DThreadState = UnsafeMutableRawPointer

public enum ProcessorServiceError: Error {
    case unknown
    case temporaryFile
    case pythonThreadState
}

public enum VertexProcessor {
    case statisticalOutlierRemoval(neighbors: Int, stdRatio: Double)
    case radiusOutlierRemoval(pointsCount: Int, radius: Double)
    case voxelDownSampling(voxelSize: Double)
    case normalsEstimation(radius: Double, maxNearestNeighbors: Int)
}

public enum FaceProcessor {
    case poissonSurfaceReconstruction(depth: Int)
}

final public class ProcessorService {

    let o3d = Python.import("open3d")
    let numpy = Python.import("numpy")
    private var tstate: O3DThreadState?

    public init() {
        #if DEBUG
        o3d.utility.VerbosityContextManager(o3d.utility.VerbosityLevel.Debug)
        #endif
    }

    // MARK: - Open3D helpers

    public func process(_ input: PLYFile, with processors: [VertexProcessor]) -> Future<Object3D, ProcessorServiceError> {
        self.tstate = PyEval_SaveThread()
        return Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.unknown))
            }
            // Python THREAD management stuff copied from Kewlbear programs
            let gstate = PyGILState_Ensure()
            defer {
                DispatchQueue.main.async {
                    guard let tstate = self.tstate else { fatalError() }
                    PyEval_RestoreThread(tstate)
                    self.tstate = nil
                }
                PyGILState_Release(gstate)
            }

            // Generate TMP file
            guard let plyFileURL = try? input.writeTemporaryFile() else {
                return promise(.failure(.temporaryFile))
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
                case let .normalsEstimation(radius, maxNearestNeighbors):
                    self.o3dNormalsEstimation(pointCloud, radius: radius, maxNearestNeighbors: maxNearestNeighbors)
                }
            }

            // Convert Open3D PointCloud to Object3D
            let object = self.convertO3D(pointCloud: pointCloud)
            promise(.success(object))
        }
    }

    public func process(_ input: PLYFile, with processors: [FaceProcessor]) -> Future<Object3D, ProcessorServiceError> {
        self.tstate = PyEval_SaveThread()
        return Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.unknown))
            }
            // Generate TMP file
            guard let plyFileURL = try? input.writeTemporaryFile() else {
                return promise(.failure(.temporaryFile))
            }

            // Python THREAD management stuff copied from Kewlbear programs
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
            let pointCloud = self.o3d.io.read_point_cloud(plyFileURL.path)

            // Apply processors
            for processor in processors {
                switch processor {
                case let .poissonSurfaceReconstruction(depth):
                    let triangleMeshes = self.surfaceReconstruction(pointCloud, depth: depth)
                    // Convert Open3D TriangleMesh back to our Face Uniform
                    let object = self.convertO3D(triangleMeshes: triangleMeshes)
                    promise(.success(object))
                }
            }
        }
    }

    private func convertO3D(pointCloud: O3DPointCloud) -> Object3D {
        let vertices: [Float3] = numpy.asarray(pointCloud.points).map { point in Float3(Float(point[0])!,
                                                                                        Float(point[1])!,
                                                                                        Float(point[2])!) }
        let colors: [Float3] = numpy.asarray(pointCloud.colors).map { color in Float3(Float(color[0])!,
                                                                                      Float(color[1])!,
                                                                                      Float(color[2])!) }
        let normals: [Float3] = numpy.asarray(pointCloud.normals).map { normal in Float3(Float(normal[0])!,
                                                                                         Float(normal[1])!,
                                                                                         Float(normal[2])!) }
        return Object3D(vertices: vertices, vertexColors: colors, vertexNormals: normals)
    }

    private func convertO3D(triangleMeshes: O3DTriangleMeshes) -> Object3D {
        let vertices: [Float3] = numpy.asarray(triangleMeshes.vertices).map { vertex in Float3(Float(vertex[0])!,
                                                                                               Float(vertex[1])!,
                                                                                               Float(vertex[2])!) }
        let colors: [Float3] = numpy.asarray(triangleMeshes.vertex_colors).map { color in Float3(Float(color[0])!,
                                                                                                 Float(color[1])!,
                                                                                                 Float(color[2])!) }
        let normals: [Float3] = numpy.asarray(triangleMeshes.vertex_normals).map { normal in Float3(Float(normal[0])!,
                                                                                                    Float(normal[1])!,
                                                                                                    Float(normal[2])!) }
        let triangles: [UInt3] = numpy.asarray(triangleMeshes.triangles).map { triangle in UInt3(UInt(triangle[0])!,
                                                                                                 UInt(triangle[1])!,
                                                                                                 UInt(triangle[2])!)}
        return Object3D(vertices: vertices, vertexColors: colors, vertexNormals: normals, triangles: triangles)
    }

    // MARK: - Open3D point cloud processing methods

    private func o3dVoxelDownSampling(_ pointCloud: PythonObject, voxelSize: Double) -> O3DPointCloud {
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
    private func o3dStatisticalOutlierRemoval(_ pointCloud: PythonObject, neighbors: Int, stdRatio: Double) -> O3DPointCloud {
        pointCloud.remove_statistical_outlier(neighbors, stdRatio)[0]
        // pointCloud.select_by_index(result[1])
    }

    /// radius_outlier_removal removes points that have few neighbors in a given sphere around them
    /// - Parameters:
    ///   - pointCloud: The target
    ///   - pointsCount: lets you pick the minimum amount of points that the sphere should contain
    ///   - radius: defines the radius of the sphere that will be used for counting the neighbors.
    /// - Returns: inlierPointCloud
    private func o3dRadiusOutlierRemoval(_ pointCloud: PythonObject, pointsCount: Int, radius: Double) -> O3DPointCloud {
        pointCloud.remove_radius_outlier(pointsCount, radius)[0]
        // pointCloud.select_by_index(result[1])
    }

    /// Computes normal for every point. The function finds adjacent points and calculate the principal axis of the adjacent points using covariance analysis.
    ///
    /// NOTE:
    /// The covariance analysis algorithm produces two opposite directions as normal candidates. Without knowing the global structure of the geometry, both can be correct. This is known as the normal orientation problem. Open3D tries to orient the normal to align with the original normal if it exists. Otherwise, Open3D does a random guess. Further orientation functions such as orient_normals_to_align_with_direction and orient_normals_towards_camera_location need to be called if the orientation is a concern.
    ///
    /// Use draw_geometries to visualize the point cloud and press n to see point normal. Key - and key + can be used to control the length of the normal.
    /// - Parameters:
    ///   - pointCloud: The target
    ///   - radius: search radius. 0.1 == It has 10cm of search radius
    ///   - maxNearestNeighbors: maximum nearest neighbor, 30 only considers up to 30 neighbors to save computation time.
    private func o3dNormalsEstimation(_ pointCloud: PythonObject, radius: Double, maxNearestNeighbors: Int) {
        let searchParam = o3d.geometry.KDTreeSearchParamHybrid(radius, maxNearestNeighbors)
        pointCloud.estimate_normals(searchParam)
    }

    /// Function that computes a triangle mesh from a oriented PointCloud pcd. This implements the Screened Poisson Reconstruction proposed in Kazhdan and Hoppe, “Screened Poisson Surface Reconstruction”, 2013. This function uses the original implementation by Kazhdan. See https://github.com/mkazhdan/PoissonRecon
    ///
    /// Parameters
    /// pcd (open3d.cpu.pybind.geometry.PointCloud) – PointCloud from which the TriangleMesh surface is reconstructed. Has to contain normals.
    ///
    /// depth (int, optional, default=8) – Maximum depth of the tree that will be used for surface reconstruction. Running at depth d corresponds to solving on a grid whose resolution is no larger than 2^d x 2^d x 2^d. Note that since the reconstructor adapts the octree to the sampling density, the specified reconstruction depth is only an upper bound.
    ///
    /// width (int, optional, default=0) – Specifies the target width of the finest level octree cells. This parameter is ignored if depth is specified
    ///
    /// scale (float, optional, default=1.1) – Specifies the ratio between the diameter of the cube used for reconstruction and the diameter of the samples’ bounding cube.
    ///
    /// linear_fit (bool, optional, default=False) – If true, the reconstructor will use linear interpolation to estimate the positions of iso-vertices.
    ///
    /// n_threads (int, optional, default=-1) – Number of threads used for reconstruction. Set to -1 to automatically determine it.
    ///
    ///  Returns
    ///  Tuple[open3d.cpu.pybind.geometry.TriangleMesh, open3d.cpu.pybind.utility.DoubleVector]
    private func surfaceReconstruction(_ pointCloud: PythonObject, depth: Int) -> O3DTriangleMeshes {
        let searchParam = o3d.geometry.KDTreeSearchParamHybrid(0.1, 30)
        pointCloud.estimate_normals(searchParam)
        return o3d.geometry.TriangleMesh.create_from_point_cloud_poisson(pointCloud, depth)[0]
    }
}
