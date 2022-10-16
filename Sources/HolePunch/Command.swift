import ArgumentParser
import Darwin
import Foundation
import System

extension String: Error {
}

// A segment is continus blocks that are all hole or not-hole.
private struct Segment {
    var offset: off_t
    var size: off_t
    var isHole: Bool
}

@main
struct Command: ParsableCommand {
    @Flag(name: [.customShort("p"), .long], help: "Show progress.")
    private var showProgress = false

    @Flag(name: [.customShort("n"), .long], help: "Dry run.")
    private var dryRun = false

    @Flag(name: .shortAndLong, help: "Verbose.")
    private var verbose = false

    @Argument(help: "Path to file to puch holes.")
    private var path: String

    private func message(_ message: @autoclosure () -> String) {
        guard verbose else {
            return
        }
        print(message())
    }

    private func updateProgress(at offset: off_t, of fileSize: off_t) {
        guard showProgress else {
            return
        }
        let percent = Int(100 * Double(offset) / Double(fileSize))
        print("Progress \(percent)%", terminator: "\r")
        fflush(stdout)
    }

    func run() throws {
        let fileDescriptor = try FileDescriptor.open(path, .readWrite)
        defer {
            do {
                try fileDescriptor.close()
            } catch {
            }
        }

        var fileSystemStat = statfs()
        if fstatfs(fileDescriptor.rawValue, &fileSystemStat) == -1 {
            throw Errno.lastErrnoValue
        }
        let blockSize = fileSystemStat.f_bsize

        var fileStat = stat()
        if fstat(fileDescriptor.rawValue, &fileStat) == -1 {
            throw Errno.lastErrnoValue
        }
        let fileSize = fileStat.st_size

        message("File system block size: \(blockSize) file size: \(fileSize)")

        let onSegment = { (segment: Segment) throws in
            message("Segment at offset: \(segment.offset) size: \(segment.size) hole: \(segment.isHole)")

            guard !dryRun, segment.isHole else {
                return
            }

            var punchhole = fpunchhole_t(
                fp_flags: 0x00,
                reserved: 0x00,
                fp_offset: segment.offset,
                fp_length: segment.size
            )
            if fcntl(fileDescriptor.rawValue, F_PUNCHHOLE, &punchhole) == -1 {
                throw Errno.lastErrnoValue
            }

            message("Puch hole at offset: \(segment.offset) size: \(segment.size)")
        }

        var buffer = [UInt8](repeating: 0x00, count: Int(blockSize))

        var segmentOffset: off_t = 0
        var blockOffset: off_t = 0
        var isLastBlockHole: Bool?

        while blockOffset < fileSize {
            updateProgress(at: blockOffset, of: fileSize)

            message("Read at offset: \(blockOffset)")

            let readSize = try buffer.withUnsafeMutableBytes { bytes -> Int in
                try fileDescriptor.read(into: bytes)
            }
            if readSize < blockSize && readSize < fileSize - blockOffset {
                throw "Failed to read block size: \(blockSize) at offset: \(blockOffset) read size: \(readSize)"
            }

            // If there is at least one non `0x00` byte in the block, that is not a hole.
            let isBlockHole = buffer[0..<readSize].allSatisfy { byte in byte == 0x00 }

            message("Block at offset: \(blockOffset) size: \(readSize) hole: \(isBlockHole)")

            if let unwrappedIsLastBlockHole = isLastBlockHole {
                // Call `onSegment` at the border of hole and not-hole blocks.
                if unwrappedIsLastBlockHole != isBlockHole {
                    let segment = Segment(
                        offset: segmentOffset,
                        size: blockOffset - segmentOffset,
                        isHole: unwrappedIsLastBlockHole
                    )
                    try onSegment(segment)

                    isLastBlockHole = isBlockHole
                    segmentOffset = blockOffset
                }
            } else {
                isLastBlockHole = isBlockHole
            }
            blockOffset += off_t(readSize)
        }

        // Call `onSegment` for the last block, if it exists.
        if let isLastBlockHole = isLastBlockHole {
            let segment = Segment(
                offset: segmentOffset,
                size: fileSize - segmentOffset,
                isHole: isLastBlockHole
            )
            try onSegment(segment)
        }

        updateProgress(at: blockOffset, of: fileSize)
    }
}
