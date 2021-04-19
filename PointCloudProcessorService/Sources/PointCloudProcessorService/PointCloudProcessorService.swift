import Foundation
import Combine

public enum PointCloudProcessingState {
    case idle
    case optimizing
}

public class PointCloudProcessorService: ObservableObject {
    @Published public var state: PointCloudProcessingState = .idle

    public init() {}
}
