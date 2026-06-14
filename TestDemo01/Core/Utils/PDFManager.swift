//
//  Untitled.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/5/13.
//

import PDFKit
import UIKit

// MARK: - 数据模型
struct PDFConfiguration {
    let defaultPageSize: CGSize
    let defaultHighlightColor: UIColor
    let maxUndoSteps: Int
}

struct PDFPageRange {
    let start: Int
    let end: Int
    
    func contains(_ index: Int) -> Bool {
        return index >= start && index <= end
    }
}

// MARK: - PDFManager 主类
final class PDFManager {
    
    // MARK: - 属性
//    private let pdfDocument: PDFDocument
    private let configuration: PDFConfiguration
    private let fileHandler: PDFFileHandler
    private let undoManager: PDFUndoManager
    
    private var currentDocument: PDFDocument

    
    // MARK: - 初始化
    init(pdfDocument: PDFDocument, configuration: PDFConfiguration = .default) {
           self.currentDocument = pdfDocument.copy() as! PDFDocument
           self.configuration = configuration
           self.fileHandler = PDFFileHandler()
           self.undoManager = PDFUndoManager(maxSteps: configuration.maxUndoSteps)
       }
    
    // MARK: - 核心功能访问
    lazy var search = PDFSearchManager(pdfDocument: currentDocument)
    lazy var edit = PDFEditManager(pdfDocument: currentDocument, undoManager: undoManager)
    lazy var annotation = PDFAnnotationManager(pdfDocument: currentDocument, undoManager: undoManager)
    lazy var merge = PDFMergeManager(pdfDocument: currentDocument)
    lazy var convert = PDFConvertManager(pdfDocument: currentDocument)
    
    // MARK: - 文档操作
    // 修改保存方法
      func save(to url: URL) -> Bool {
          return fileHandler.save(document: currentDocument, to: url)
      }
    
     func undo() -> Bool {
         guard let document = undoManager.undo(currentDocument: currentDocument) else { return false }
         currentDocument = document.copy() as! PDFDocument
         return true
     }
     
     func redo() -> Bool {
         guard let document = undoManager.redo(currentDocument: currentDocument) else { return false }
         currentDocument = document.copy() as! PDFDocument
         return true
     }
    
    // MARK: - 文档信息
    var pageCount: Int {
        return currentDocument.pageCount
    }
    
    func getThumbnail(for pageNumber: Int, size: CGSize) -> UIImage? {
        return PDFThumbnailGenerator.generateThumbnail(for: currentDocument, pageNumber: pageNumber, size: size)
    }
}

// MARK: - 默认配置
extension PDFConfiguration {
    static let `default` = PDFConfiguration(
        defaultPageSize: CGSize(width: 612, height: 792), // A4 尺寸 (72 dpi)
        defaultHighlightColor: .yellow,
        maxUndoSteps: 10
    )
}

// MARK: - 搜索管理 (Search)
final class PDFSearchManager {
    private let pdfDocument: PDFDocument
    
    init(pdfDocument: PDFDocument) {
        self.pdfDocument = pdfDocument
    }
    
    func search(text: String, options: NSString.CompareOptions = .caseInsensitive) -> [PDFSelection] {
        return pdfDocument.findString(text, withOptions: options)
    }
    
    func highlight(selections: [PDFSelection], color: UIColor) {
        selections.forEach { selection in
            selection.pages.forEach { page in
                let highlight = PDFAnnotation(
                    bounds: selection.bounds(for: page),
                    forType: .highlight,
                    withProperties: nil
                )
                highlight.color = color
                page.addAnnotation(highlight)
            }
        }
    }
}

// MARK: - 编辑管理 (Edit)
final class PDFEditManager {
    private let pdfDocument: PDFDocument
    private let undoManager: PDFUndoManager
    
    init(pdfDocument: PDFDocument, undoManager: PDFUndoManager) {
        self.pdfDocument = pdfDocument
        self.undoManager = undoManager
    }
    
    func addTextAnnotation(text: String, at point: CGPoint, in page: PDFPage, fontSize: CGFloat = 14, color: UIColor = .black) {
        undoManager.saveState(document: pdfDocument)
        
        let annotation = PDFAnnotation(
            bounds: CGRect(x: point.x, y: point.y, width: 200, height: fontSize + 10),
            forType: .freeText,
            withProperties: nil
        )
        annotation.font = UIFont.systemFont(ofSize: fontSize)
        annotation.color = color
        annotation.contents = text
        page.addAnnotation(annotation)
    }
    
    func removePage(at index: Int) -> Bool {
        guard index < pdfDocument.pageCount else { return false }
        undoManager.saveState(document: pdfDocument)
        pdfDocument.removePage(at: index)
        return true
    }
    
    func rotatePage(at index: Int, rotation: Int) -> Bool {
        guard let page = pdfDocument.page(at: index) else { return false }
        undoManager.saveState(document: pdfDocument)
        page.rotation = (page.rotation + rotation) % 360
        return true
    }
}

// MARK: - 标注管理 (Annotation)
final class PDFAnnotationManager {
    private let pdfDocument: PDFDocument
    private let undoManager: PDFUndoManager
    private var currentDrawing: PDFAnnotation?
    
    init(pdfDocument: PDFDocument, undoManager: PDFUndoManager) {
        self.pdfDocument = pdfDocument
        self.undoManager = undoManager
    }
    
    func startDrawing(on page: PDFPage, color: UIColor = .red, lineWidth: CGFloat = 2.0) {
        undoManager.saveState(document: pdfDocument)
        
        currentDrawing = PDFAnnotation(
            bounds: page.bounds(for: .mediaBox),
            forType: .ink,
            withProperties: nil
        )
        currentDrawing?.color = color
        currentDrawing?.border = PDFBorder()
        currentDrawing?.border?.lineWidth = lineWidth
    }
    
    func addLine(to point: CGPoint, on page: PDFPage) {
        guard let currentDrawing = currentDrawing else { return }
        
        let path = UIBezierPath()
        if let lastPoint = currentDrawing.paths?.last?.currentPoint {
            path.move(to: lastPoint)
        } else {
            path.move(to: point)
        }
        path.addLine(to: point)
        currentDrawing.add(path)
    }
    
    func endDrawing(on page: PDFPage) {
        guard let currentDrawing = currentDrawing else { return }
        page.addAnnotation(currentDrawing)
        self.currentDrawing = nil
    }
    
    func clearAnnotations(on page: PDFPage) {
        undoManager.saveState(document: pdfDocument)
        for annotation in page.annotations {
            page.removeAnnotation(annotation)
        }
    }
}

// MARK: - 合并管理 (Merge)
final class PDFMergeManager {
    private let pdfDocument: PDFDocument
    
    init(pdfDocument: PDFDocument) {
        self.pdfDocument = pdfDocument
    }
    
    func merge(with documents: [PDFDocument], at position: Int? = nil) -> PDFDocument {
        let mergedDocument = pdfDocument.copy() as! PDFDocument
        let insertPosition = position ?? mergedDocument.pageCount
        
        for (index, document) in documents.enumerated() {
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    mergedDocument.insert(page, at: insertPosition + index * document.pageCount + i)
                }
            }
        }
        
        return mergedDocument
    }
    
    func extractPages(_ range: PDFPageRange) -> PDFDocument {
        let newDocument = PDFDocument()
        
        for i in range.start...range.end {
            if i < pdfDocument.pageCount, let page = pdfDocument.page(at: i) {
                newDocument.insert(page, at: newDocument.pageCount)
            }
        }
        
        return newDocument
    }
}

// MARK: - 转换管理 (Convert)
final class PDFConvertManager {
    private let pdfDocument: PDFDocument
    
    init(pdfDocument: PDFDocument) {
        self.pdfDocument = pdfDocument
    }
    
    func toImages(dpi: CGFloat = 72.0) -> [UIImage] {
        var images = [UIImage]()
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                
                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            images.append(image)
        }
        
        return images
    }
    
    func toText() -> String {
        var fullText = ""
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i),
                  let pageContent = page.string else { continue }
            
            fullText += pageContent + "\n\n"
        }
        
        return fullText
    }
}

// MARK: - 工具类 (Utilities)

// 文件处理
final class PDFFileHandler {
    func save(document: PDFDocument, to url: URL) -> Bool {
        guard let data = document.dataRepresentation() else { return false }
        
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Error saving PDF: \(error)")
            return false
        }
    }
    
    static func load(from url: URL) -> PDFDocument? {
        return PDFDocument(url: url)
    }
}

// 撤销管理
// MARK: - PDFUndoManager (修正版)
final class PDFUndoManager {
    private var undoStack: [Data] = []
    private var redoStack: [Data] = []
    private let maxSteps: Int
    
    init(maxSteps: Int) {
        self.maxSteps = maxSteps
    }
    
    func saveState(document: PDFDocument) {
        guard let data = document.dataRepresentation() else { return }
        
        undoStack.append(data)
        if undoStack.count > maxSteps {
            undoStack.removeFirst()
        }
        
        redoStack.removeAll()
    }
    
    func undo(currentDocument: PDFDocument) -> PDFDocument? {
        guard !undoStack.isEmpty else { return nil }
        
        // 保存当前状态到重做栈
        if let currentData = currentDocument.dataRepresentation() {
            redoStack.append(currentData)
            if redoStack.count > maxSteps {
                redoStack.removeFirst()
            }
        }
        
        let lastData = undoStack.removeLast()
        return PDFDocument(data: lastData)
    }
    
    func redo(currentDocument: PDFDocument) -> PDFDocument? {
        guard !redoStack.isEmpty else { return nil }
        
        // 保存当前状态到撤销栈
        if let currentData = currentDocument.dataRepresentation() {
            undoStack.append(currentData)
            if undoStack.count > maxSteps {
                undoStack.removeFirst()
            }
        }
        
        let lastData = redoStack.removeLast()
        return PDFDocument(data: lastData)
    }
}

// 缩略图生成
final class PDFThumbnailGenerator {
    static func generateThumbnail(for document: PDFDocument, pageNumber: Int, size: CGSize) -> UIImage? {
        guard let page = document.page(at: pageNumber) else { return nil }
        
        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(size.width / pageRect.width, size.height / pageRect.height)
        let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: scaledSize))
            
            ctx.cgContext.translateBy(x: 0.0, y: scaledSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}

/*
 // 初始化
 guard let document = PDFDocument(url: somePDFURL) else { return }
 let pdfManager = PDFManager(pdfDocument: document)

 // 搜索功能
 let results = pdfManager.search.search(text: "重要内容")
 pdfManager.search.highlight(selections: results, color: .yellow)

 // 编辑功能
 if let firstPage = document.page(at: 0) {
     pdfManager.edit.addTextAnnotation(text: "备注", at: CGPoint(x: 50, y: 50), in: firstPage)
 }

 // 涂鸦功能
 if let page = document.page(at: 0) {
     pdfManager.annotation.startDrawing(on: page, color: .blue, lineWidth: 3.0)
     pdfManager.annotation.addLine(to: CGPoint(x: 100, y: 100), on: page)
     pdfManager.annotation.endDrawing(on: page)
 }

 // 合并文档
 let anotherDocument = PDFDocument(url: anotherPDFURL)!
 let mergedDoc = pdfManager.merge.merge(with: [anotherDocument])

 // 格式转换
 let images = pdfManager.convert.toImages()
 let textContent = pdfManager.convert.toText()

 // 撤销操作
 pdfManager.undo()

 // 保存文档
 let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.pdf")
 pdfManager.save(to: outputURL)
 */
