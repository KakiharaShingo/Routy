//
//  PrefectureShapeData.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/20.
//

import SwiftUI

/// 都道府県のSVG形状データ
struct PrefectureShapeData {
    let prefectureId: Int
    let pathData: String
    let transform: CGAffineTransform

    // パース済みのパスをキャッシュ
    private static var pathCache: [Int: Path] = [:]

    /// パース済みのSwiftUI Pathを取得（キャッシュ利用）
    func cachedPath() -> Path {
        if let cached = Self.pathCache[prefectureId] {
            return cached
        }

        let bezierPath = SVGPathParser.parse(pathData)
        var path = Path(bezierPath.cgPath)
        path = path.applying(transform)

        Self.pathCache[prefectureId] = path
        return path
    }

    /// すべての都道府県の形状データ
    static let allShapes: [Int: PrefectureShapeData] = {
        var shapes: [Int: PrefectureShapeData] = [:]

        // 自動生成されたSVGパスデータ
        shapes[47] = PrefectureShapeData(
            prefectureId: 47,
            pathData: "M4,109 L6,110 L4,111 L0,110 Z M48,121 L55,123 L51,129 L39,124 L42,122 L44,125 L46,118 Z M132,113 L130,110 L132,110 L130,108 L133,105 L132,100 L135,108 L142,114 Z M225,23 L224,28 L219,23 L223,21 Z M73,117 L77,112 L79,113 L73,120 L72,126 L66,127 L64,125 L67,122 L63,119 L71,120 Z M287,20 L291,17 L286,15 L285,8 L292,10 L292,14 L299,13 L298,11 L307,0 L309,5 L309,9 L305,15 L300,15 L299,19 L293,19 L294,21 L288,25 L281,25 L286,34 L281,31 L276,39 L280,41 L270,46 L270,38 L277,32 L275,24 L280,25 Z M127,106 L126,103 L128,104 Z M279,8 L279,6 L283,8 Z M293,11 L294,13 L292,12 Z",
            transform: CGAffineTransform(translationX: 52.0, y: 193.0)
        )
        
        shapes[46] = PrefectureShapeData(
            prefectureId: 46,
            pathData: "M23,949 L26,951 L23,952 Z M33,960 L32,954 L39,950 L48,956 L47,961 L41,965 L35,964 Z M64,953 L64,958 L59,959 L58,952 L62,949 L63,939 L70,929 L71,938 Z M38,844 L43,848 L52,844 L57,850 L56,852 L61,859 L66,864 L65,869 L70,871 L73,880 L80,881 L80,888 L78,891 L75,890 L70,896 L75,899 L73,903 L76,902 L69,905 L66,910 L50,918 L50,913 L55,910 L59,898 L53,889 L54,884 L48,881 L53,879 L54,883 L57,884 L61,878 L54,872 L50,874 L44,887 L46,898 L51,901 L49,906 L43,907 L40,901 L27,901 L28,897 L25,896 L27,894 L22,890 L31,890 L35,880 L32,871 L27,867 L30,860 L28,848 L31,846 L35,848 Z M31,837 L34,836 L33,838 Z M27,848 L24,842 L29,840 L30,844 Z M4,868 L6,865 L7,867 L2,875 L0,874 Z M12,864 L9,861 L14,861 Z M284,149 L280,150 L279,146 L289,144 Z M301,126 L301,118 L306,118 L305,122 L309,126 L308,129 L303,132 L300,128 Z M363,98 L360,99 L359,97 L365,93 Z M344,90 L331,98 L335,101 L330,104 L327,103 L329,107 L323,102 L325,99 L316,97 L324,97 L325,95 L321,94 L335,88 L337,90 L339,86 L344,85 L342,89 L344,87 L345,89 L347,82 L349,88 Z M324,108 L322,106 L320,108 L318,101 L323,102 L322,105 L328,107 L325,109 L326,107 Z M355,12 L352,16 L352,13 Z M361,1 L363,0 L365,4 Z",
            transform: CGAffineTransform(translationX: 96.0, y: 17.0)
        )
        
        shapes[45] = PrefectureShapeData(
            prefectureId: 45,
            pathData: "M36,0 L38,1 L43,0 L48,5 L56,5 L59,1 L63,2 L63,7 L65,7 L54,17 L53,21 L56,22 L52,23 L51,25 L53,26 L47,34 L41,51 L39,74 L34,79 L32,91 L27,89 L22,84 L24,81 L24,74 L17,73 L14,64 L9,62 L10,57 L5,52 L0,45 L1,43 L22,41 L19,35 L23,30 L18,23 L18,16 L23,14 L32,0 Z",
            transform: CGAffineTransform(translationX: 152.0, y: 824.0)
        )
        
        shapes[44] = PrefectureShapeData(
            prefectureId: 44,
            pathData: "M0,34 L3,29 L0,26 L2,24 L1,19 L5,13 L12,9 L19,10 L20,3 L33,7 L38,0 L47,4 L49,10 L46,18 L43,17 L43,20 L35,22 L36,26 L40,28 L56,27 L50,36 L56,36 L53,38 L56,40 L61,38 L62,41 L57,41 L55,45 L65,49 L59,49 L61,51 L57,54 L60,55 L54,56 L54,60 L52,60 L52,55 L48,54 L45,58 L37,58 L32,53 L27,54 L25,53 L21,49 L22,43 L15,30 L9,30 L10,36 L8,39 Z",
            transform: CGAffineTransform(translationX: 163.0, y: 771.0)
        )
        
        shapes[43] = PrefectureShapeData(
            prefectureId: 43,
            pathData: "M8,37 L13,38 L13,48 L5,57 L1,58 L1,52 L5,51 L0,50 L4,40 L3,37 L8,37 Z M20,47 L14,47 L12,43 L19,39 L26,39 L23,47 L20,47 Z M24,34 L26,34 L26,38 L23,38 L24,34 Z M38,67 L33,61 L24,65 L19,61 L32,46 L30,40 L32,41 L31,39 L37,34 L26,34 L34,28 L35,23 L27,15 L26,10 L31,10 L30,7 L35,3 L39,4 L40,0 L48,5 L56,10 L58,7 L57,1 L63,1 L70,14 L69,20 L73,24 L69,24 L60,38 L55,40 L55,47 L60,54 L56,59 L59,65 L38,67 Z",
            transform: CGAffineTransform(translationX: 115.0, y: 800.0)
        )
        
        shapes[42] = PrefectureShapeData(
            prefectureId: 42,
            pathData: "M53,1 L55,0 L57,2 L54,5 L55,9 L49,15 L48,19 L51,18 L49,22 L51,21 L48,25 L48,20 L46,22 L46,19 L45,22 L42,20 L44,20 L45,15 L47,15 L45,14 L49,10 L46,8 L48,3 L52,3 L53,1 Z M46,29 L43,35 L37,36 L40,22 L41,24 L45,25 L44,22 L45,26 L48,25 L46,29 Z M67,59 L68,61 L64,63 L60,59 L62,59 L61,56 L64,53 L67,55 L66,57 L68,58 L67,59 Z M28,110 L25,115 L26,110 L23,107 L26,106 L26,102 L28,102 L30,94 L28,105 L33,106 L30,108 L28,106 L28,110 Z M24,112 L21,111 L21,109 L23,111 L22,108 L24,112 Z M19,113 L20,110 L19,116 L16,111 L19,113 Z M6,118 L9,117 L10,119 L12,115 L16,125 L9,124 L9,129 L0,126 L1,124 L3,126 L4,125 L2,125 L5,122 L4,116 L6,118 Z M65,80 L62,81 L64,78 L65,80 Z M67,82 L70,84 L67,86 L67,82 Z M29,88 L31,85 L33,87 L29,88 Z M54,76 L51,77 L55,74 L54,76 Z M66,86 L64,89 L66,96 L73,98 L72,102 L78,109 L86,112 L79,117 L92,118 L94,123 L92,130 L82,134 L80,128 L85,124 L84,122 L79,121 L71,123 L68,129 L60,134 L64,129 L63,126 L65,127 L67,123 L64,125 L63,118 L59,117 L56,111 L59,100 L63,104 L62,108 L63,106 L66,108 L64,115 L75,118 L71,112 L72,107 L69,103 L66,105 L65,99 L62,99 L62,97 L58,100 L60,98 L57,96 L57,93 L57,95 L53,93 L57,87 L54,86 L55,83 L60,82 L60,85 L65,84 L66,86 Z M49,88 L48,92 L42,94 L47,91 L45,89 L48,84 L52,84 L54,81 L55,84 L49,88 Z M15,115 L15,113 L18,116 L15,118 L15,115 Z M64,101 L63,104 L62,101 L64,98 L64,101 Z",
            transform: CGAffineTransform(translationX: 44.0, y: 700.0)
        )
        
        shapes[41] = PrefectureShapeData(
            prefectureId: 41,
            pathData: "M15,6 L28,6 L34,12 L41,10 L40,16 L32,21 L30,28 L25,23 L19,29 L22,39 L14,36 L8,29 L9,25 L2,23 L0,16 L2,13 L5,17 L4,13 L6,9 L2,6 L3,4 L6,6 L6,0 L7,2 L11,2 L12,7 Z",
            transform: CGAffineTransform(translationX: 108.0, y: 773.0)
        )
        
        shapes[40] = PrefectureShapeData(
            prefectureId: 40,
            pathData: "M40,53 L32,48 L31,52 L27,51 L22,55 L23,58 L18,58 L18,52 L15,49 L17,42 L25,37 L26,31 L19,33 L13,27 L0,27 L7,23 L3,20 L10,15 L13,21 L20,20 L21,15 L17,17 L14,14 L19,15 L23,12 L25,5 L35,3 L36,0 L42,1 L38,5 L41,5 L43,2 L46,4 L53,0 L49,8 L52,10 L50,11 L55,22 L60,22 L59,29 L52,28 L45,32 L41,38 L42,43 L40,45 L43,48 Z",
            transform: CGAffineTransform(translationX: 123.0, y: 752.0)
        )
        
        shapes[39] = PrefectureShapeData(
            prefectureId: 39,
            pathData: "M61,0 L74,6 L80,4 L81,12 L88,13 L86,17 L88,21 L94,22 L87,41 L75,25 L65,21 L55,23 L55,21 L56,24 L44,28 L50,28 L44,29 L42,32 L41,29 L38,33 L39,38 L37,44 L34,44 L30,52 L25,53 L25,61 L22,64 L25,70 L21,66 L14,68 L9,65 L5,67 L6,61 L10,60 L9,57 L6,57 L8,54 L5,41 L9,44 L15,36 L20,33 L16,24 L27,23 L30,13 L37,4 L61,0 Z M1,69 L0,70 L0,67 L1,69 Z",
            transform: CGAffineTransform(translationX: 251.0, y: 765.0)
        )
        
        shapes[38] = PrefectureShapeData(
            prefectureId: 38,
            pathData: "M34,21 L31,20 L35,17 L34,21 Z M55,6 L51,6 L55,0 L57,3 L55,6 Z M60,5 L61,5 L60,7 L57,6 L60,5 Z M58,10 L54,12 L55,7 L60,8 L58,10 Z M32,85 L25,83 L25,86 L23,86 L24,81 L27,82 L21,76 L24,76 L22,72 L25,72 L22,71 L23,69 L20,67 L24,70 L28,66 L28,63 L24,63 L27,60 L19,60 L21,57 L19,56 L22,51 L16,50 L8,56 L0,57 L35,37 L41,18 L50,15 L48,11 L51,10 L59,24 L70,20 L80,22 L84,18 L89,20 L87,28 L63,32 L56,41 L53,51 L42,52 L46,61 L41,64 L35,72 L31,69 L34,82 L32,85 Z",
            transform: CGAffineTransform(translationX: 225.0, y: 737.0)
        )
        
        shapes[37] = PrefectureShapeData(
            prefectureId: 37,
            pathData: "M6,33 L1,31 L4,21 L0,17 L6,20 L19,10 L26,13 L30,9 L31,14 L34,11 L37,14 L36,17 L45,22 L44,25 L31,23 L22,30 L15,27 L6,33 Z M27,5 L25,4 L29,4 L27,5 Z M40,0 L42,0 L40,8 L38,7 L38,5 L35,9 L35,5 L31,3 L40,0 Z",
            transform: CGAffineTransform(translationX: 308.0, y: 724.0)
        )
        
        shapes[36] = PrefectureShapeData(
            prefectureId: 36,
            pathData: "M50,2 L52,0 L51,4 L50,2 Z M41,2 L49,0 L49,3 L52,4 L48,13 L55,20 L50,24 L57,26 L38,36 L33,43 L27,42 L25,38 L27,34 L20,33 L19,25 L13,27 L0,21 L2,13 L11,7 L18,10 L27,3 L40,5 L41,2 Z",
            transform: CGAffineTransform(translationX: 312.0, y: 744.0)
        )
        
        shapes[35] = PrefectureShapeData(
            prefectureId: 35,
            pathData: "M45,0 L47,6 L43,11 L45,15 L50,15 L48,20 L50,24 L56,22 L58,24 L61,20 L60,16 L64,14 L64,21 L66,23 L67,29 L72,31 L72,36 L69,36 L70,44 L65,46 L65,54 L61,48 L57,48 L52,42 L47,44 L50,41 L46,38 L35,42 L32,39 L30,42 L29,40 L27,42 L27,38 L25,43 L21,45 L19,43 L16,45 L15,40 L9,36 L3,43 L3,36 L0,32 L4,27 L1,21 L4,17 L10,17 L5,15 L7,12 L16,14 L17,17 L24,17 L30,15 L29,12 L41,1 L43,2 L45,0 Z M64,54 L59,56 L62,52 L64,54 Z M75,50 L83,48 L78,50 L77,53 L73,50 L69,53 L67,48 L70,46 L75,50 Z M18,15 L18,13 L22,14 L18,15 Z M51,46 L48,46 L51,43 L51,46 Z",
            transform: CGAffineTransform(translationX: 168.0, y: 710.0)
        )
        
        shapes[34] = PrefectureShapeData(
            prefectureId: 34,
            pathData: "M73,40 L72,42 L69,40 L72,43 L70,42 L68,47 L63,45 L63,42 L54,44 L51,48 L39,49 L37,53 L30,55 L28,53 L25,56 L26,53 L23,47 L25,45 L17,44 L9,51 L10,54 L5,52 L4,46 L2,44 L2,37 L0,35 L5,30 L7,24 L6,22 L12,17 L20,19 L22,16 L27,18 L35,16 L32,11 L38,8 L45,0 L58,2 L65,4 L68,7 L66,14 L70,19 L69,24 L73,40 Z M45,53 L43,56 L41,53 L46,51 L45,53 Z M21,54 L20,50 L23,51 L22,59 L19,59 L21,56 L17,51 L21,54 Z M15,48 L16,50 L12,52 L15,48 Z M35,57 L33,56 L36,56 L35,57 Z M24,58 L26,58 L25,61 L28,61 L26,63 L20,62 L23,56 L26,56 L24,58 Z M59,49 L59,52 L56,49 L59,49 Z M57,50 L53,52 L54,50 L57,50 Z M60,44 L62,45 L59,47 L60,44 Z",
            transform: CGAffineTransform(translationX: 230.0, y: 687.0)
        )
        
        shapes[33] = PrefectureShapeData(
            prefectureId: 33,
            pathData: "M58,8 L59,14 L51,22 L52,29 L50,32 L54,38 L53,41 L46,39 L49,42 L43,49 L34,48 L39,49 L36,53 L34,52 L33,57 L27,55 L25,58 L23,52 L23,55 L19,51 L15,55 L10,52 L12,56 L8,54 L4,38 L5,33 L1,28 L3,21 L0,18 L1,15 L8,14 L7,10 L14,10 L13,7 L15,6 L18,0 L25,2 L29,7 L39,1 L38,3 L45,6 L46,12 Z",
            transform: CGAffineTransform(translationX: 295.0, y: 673.0)
        )
        
        shapes[32] = PrefectureShapeData(
            prefectureId: 32,
            pathData: "M74,14 L78,13 L75,17 L72,15 L73,19 L71,16 L74,14 Z M79,16 L77,19 L77,15 L79,14 L81,17 L79,16 Z M83,5 L88,0 L93,5 L92,9 L89,9 L91,11 L86,12 L83,5 Z M2,100 L10,98 L25,84 L35,78 L41,70 L52,65 L55,59 L53,55 L70,51 L76,46 L79,49 L87,48 L84,50 L82,51 L88,59 L87,68 L79,70 L81,73 L77,79 L64,77 L57,85 L51,88 L54,93 L46,95 L41,93 L39,96 L31,94 L25,99 L26,101 L24,107 L19,112 L21,114 L17,116 L18,120 L15,124 L13,122 L7,124 L5,120 L7,115 L2,115 L0,111 L4,106 L2,100 Z",
            transform: CGAffineTransform(translationX: 211.0, y: 610.0)
        )
        
        shapes[31] = PrefectureShapeData(
            prefectureId: 31,
            pathData: "M7,33 L0,31 L4,25 L2,22 L10,20 L11,11 L5,3 L7,2 L9,6 L15,8 L23,4 L34,6 L55,5 L64,0 L71,17 L71,21 L65,23 L53,27 L52,21 L45,18 L46,16 L36,22 L32,17 L25,15 L22,21 L20,22 L21,25 L14,25 L15,29 L8,30 Z",
            transform: CGAffineTransform(translationX: 288.0, y: 658.0)
        )
        
        shapes[30] = PrefectureShapeData(
            prefectureId: 30,
            pathData: "M41,32 L44,38 L49,41 L45,46 L46,50 L38,55 L37,59 L35,59 L36,56 L19,51 L14,44 L17,41 L9,37 L4,30 L0,30 L3,25 L0,24 L6,21 L1,18 L5,16 L4,14 L8,14 L0,6 L2,3 L5,6 L31,0 L35,9 L31,10 L25,17 L30,24 L28,30 L41,32 Z M49,23 L49,26 L44,29 L44,26 L49,23 Z",
            transform: CGAffineTransform(translationX: 385.0, y: 737.0)
        )
        
        shapes[29] = PrefectureShapeData(
            prefectureId: 29,
            pathData: "M24,48 L19,51 L19,54 L17,54 L17,57 L16,57 L3,55 L5,49 L0,42 L6,35 L10,34 L6,25 L8,20 L6,11 L11,0 L17,5 L21,2 L25,5 L27,3 L29,7 L26,8 L28,9 L27,13 L36,18 L28,24 L31,29 L29,30 L31,33 L29,37 L30,44 L29,47 Z",
            transform: CGAffineTransform(translationX: 410.0, y: 712.0)
        )
        
        shapes[28] = PrefectureShapeData(
            prefectureId: 28,
            pathData: "M31,90 L23,93 L23,88 L20,89 L20,86 L38,67 L39,69 L32,79 L35,88 L31,90 Z M3,59 L4,56 L0,50 L2,47 L1,40 L9,32 L8,26 L14,24 L14,20 L7,3 L16,0 L33,1 L32,5 L36,10 L41,9 L42,11 L42,17 L36,17 L35,23 L42,28 L47,26 L49,33 L59,35 L58,40 L55,41 L56,45 L62,48 L60,49 L62,60 L59,62 L53,60 L40,66 L25,56 L11,57 L11,53 L8,58 L5,56 L3,59 Z",
            transform: CGAffineTransform(translationX: 345.0, y: 655.0)
        )
        
        shapes[27] = PrefectureShapeData(
            prefectureId: 27,
            pathData: "M16,0 L24,8 L28,5 L27,8 L31,9 L34,17 L29,28 L31,37 L29,42 L3,48 L0,45 L7,44 L14,37 L17,28 L19,30 L17,22 L20,20 L18,9 L20,8 L14,5 L13,1 Z",
            transform: CGAffineTransform(translationX: 387.0, y: 695.0)
        )
        
        shapes[26] = PrefectureShapeData(
            prefectureId: 26,
            pathData: "M44,63 L41,55 L37,54 L38,51 L34,54 L26,46 L27,41 L17,39 L15,32 L10,34 L3,29 L4,23 L10,23 L10,17 L9,15 L4,16 L0,11 L1,7 L3,10 L2,8 L19,0 L23,7 L15,14 L18,15 L20,11 L20,15 L24,17 L23,21 L25,18 L27,19 L25,14 L31,11 L32,14 L31,20 L34,25 L46,27 L51,32 L48,46 L51,56 L55,56 L59,62 L60,66 L58,68 L54,65 L50,68 Z",
            transform: CGAffineTransform(translationX: 377.0, y: 649.0)
        )
        
        shapes[25] = PrefectureShapeData(
            prefectureId: 25,
            pathData: "M20,0 L27,3 L28,9 L31,9 L34,16 L35,19 L31,29 L33,30 L34,40 L30,50 L24,53 L17,50 L16,55 L13,56 L9,50 L5,50 L2,40 L5,26 L0,21 L3,17 L6,18 L9,11 L12,13 L18,10 L18,7 L21,8 L20,0 Z M20,13 L20,16 L18,13 L14,16 L16,24 L8,32 L8,36 L5,42 L7,45 L9,36 L15,35 L16,31 L25,25 L26,21 L20,13 Z",
            transform: CGAffineTransform(translationX: 423.0, y: 655.0)
        )
        
        shapes[24] = PrefectureShapeData(
            prefectureId: 24,
            pathData: "M8,95 L3,92 L0,86 L1,86 L1,83 L3,83 L8,80 L8,77 L13,76 L14,73 L13,66 L15,62 L13,59 L15,58 L12,53 L20,47 L11,42 L12,38 L10,37 L13,36 L11,32 L10,28 L13,27 L14,22 L21,25 L27,22 L31,12 L30,2 L36,0 L43,7 L48,15 L42,16 L43,20 L36,32 L35,40 L51,47 L53,52 L56,51 L55,55 L50,55 L55,56 L55,61 L51,62 L53,60 L50,58 L49,60 L43,61 L46,57 L42,57 L39,62 L39,60 L36,63 L34,61 L34,64 L32,62 L25,66 L22,68 L23,73 L21,72 L22,70 L18,73 L22,77 L20,77 L22,80 L19,78 L20,81 L13,85 Z",
            transform: CGAffineTransform(translationX: 426.0, y: 683.0)
        )
        
        shapes[23] = PrefectureShapeData(
            prefectureId: 23,
            pathData: "M42,46 L18,52 L20,47 L23,49 L31,43 L33,46 L35,43 L34,40 L28,37 L26,41 L18,40 L14,37 L16,29 L12,40 L16,45 L13,45 L9,41 L10,36 L8,33 L8,28 L12,21 L5,25 L0,17 L1,11 L5,3 L15,0 L21,8 L26,10 L33,8 L39,12 L46,8 L47,14 L52,11 L60,13 L50,33 L42,38 Z",
            transform: CGAffineTransform(translationX: 469.0, y: 673.0)
        )
        
        shapes[22] = PrefectureShapeData(
            prefectureId: 22,
            pathData: "M73,14 L77,14 L77,27 L83,31 L81,36 L85,42 L85,46 L78,55 L77,61 L70,65 L64,59 L67,45 L65,41 L66,38 L72,37 L62,31 L55,33 L51,38 L53,41 L44,45 L42,54 L36,61 L38,65 L25,61 L0,60 L0,52 L8,47 L18,27 L33,17 L33,5 L37,0 L40,8 L39,19 L44,20 L48,29 L53,27 L52,20 L56,12 L61,17 Z",
            transform: CGAffineTransform(translationX: 511.0, y: 659.0)
        )
        
        shapes[21] = PrefectureShapeData(
            prefectureId: 21,
            pathData: "M66,4 L69,10 L64,20 L67,24 L66,28 L60,35 L55,35 L53,40 L59,43 L64,50 L62,53 L68,59 L66,63 L68,66 L65,66 L67,70 L65,73 L58,77 L52,73 L45,75 L40,73 L34,65 L24,68 L20,76 L19,82 L12,75 L6,77 L4,76 L8,66 L7,63 L4,56 L1,56 L0,50 L5,41 L11,44 L12,42 L25,41 L28,37 L22,29 L24,23 L29,13 L26,10 L30,5 L34,7 L35,11 L44,0 L47,2 L52,0 L52,2 L56,0 Z",
            transform: CGAffineTransform(translationX: 450.0, y: 608.0)
        )
        
        shapes[20] = PrefectureShapeData(
            prefectureId: 20,
            pathData: "M68,18 L59,21 L60,23 L55,27 L54,34 L57,39 L66,39 L67,45 L64,47 L66,53 L63,54 L66,57 L66,63 L70,65 L71,70 L68,72 L64,69 L58,71 L53,66 L43,77 L46,80 L43,82 L45,87 L41,92 L41,104 L26,114 L18,112 L13,115 L12,109 L14,106 L12,102 L15,102 L13,99 L15,95 L9,89 L11,86 L6,79 L0,76 L2,71 L7,71 L13,64 L14,60 L11,56 L16,46 L13,40 L19,32 L18,29 L21,28 L22,17 L27,10 L27,7 L34,8 L34,13 L36,14 L44,10 L48,12 L48,7 L53,2 L60,0 L63,2 L63,7 L68,11 Z",
            transform: CGAffineTransform(translationX: 503.0, y: 572.0)
        )
        
        shapes[19] = PrefectureShapeData(
            prefectureId: 19,
            pathData: "M2,21 L0,16 L3,14 L0,11 L10,0 L15,5 L21,3 L25,6 L28,4 L39,7 L43,15 L48,18 L47,27 L38,35 L26,38 L21,33 L17,41 L18,48 L13,50 L9,41 L4,40 L5,29 Z",
            transform: CGAffineTransform(translationX: 546.0, y: 638.0)
        )
        
        shapes[18] = PrefectureShapeData(
            prefectureId: 18,
            pathData: "M40,0 L46,8 L56,9 L61,14 L66,13 L64,19 L70,27 L67,31 L54,32 L53,34 L47,31 L42,40 L35,37 L36,45 L33,44 L33,47 L27,50 L24,48 L21,55 L18,54 L15,58 L3,56 L0,51 L1,45 L3,49 L10,46 L6,49 L13,50 L15,47 L13,48 L13,45 L19,47 L17,45 L20,43 L18,40 L26,41 L25,35 L28,33 L29,38 L31,39 L32,32 L25,19 L34,6 L34,2 Z",
            transform: CGAffineTransform(translationX: 408.0, y: 618.0)
        )
        
        shapes[17] = PrefectureShapeData(
            prefectureId: 17,
            pathData: "M37,26 L34,23 L41,23 L37,26 Z M28,77 L31,80 L26,90 L21,91 L16,86 L6,85 L0,77 L15,62 L26,44 L27,33 L25,29 L25,24 L22,23 L27,10 L52,0 L56,1 L57,5 L51,6 L50,15 L46,14 L39,22 L37,18 L34,19 L32,28 L38,30 L41,26 L41,36 L33,38 L31,48 L28,50 L30,54 L28,57 L29,61 L27,69 L28,77 Z",
            transform: CGAffineTransform(translationX: 448.0, y: 541.0)
        )
        
        shapes[16] = PrefectureShapeData(
            prefectureId: 16,
            pathData: "M41,37 L31,33 L27,35 L27,33 L22,35 L19,33 L10,44 L9,40 L5,38 L1,43 L0,35 L2,27 L1,23 L3,20 L1,16 L4,14 L6,4 L14,2 L11,8 L23,15 L31,11 L33,3 L43,0 L47,3 L50,14 L49,25 L46,26 L47,29 Z",
            transform: CGAffineTransform(translationX: 475.0, y: 575.0)
        )
        
        shapes[15] = PrefectureShapeData(
            prefectureId: 15,
            pathData: "M7,113 L4,102 L0,99 L14,94 L23,87 L30,87 L45,75 L55,60 L60,46 L79,34 L80,36 L79,35 L85,28 L94,0 L102,3 L102,10 L111,16 L109,20 L101,23 L101,31 L98,39 L101,44 L104,46 L95,56 L97,65 L89,65 L88,68 L79,69 L78,72 L80,76 L76,82 L81,87 L80,101 L73,94 L71,98 L67,99 L68,104 L65,105 L65,108 L53,114 L53,107 L48,103 L48,98 L45,96 L38,98 L33,103 L33,108 L29,106 L21,110 L19,109 L19,104 L12,103 L12,106 L7,113 Z M36,46 L28,47 L35,38 L33,35 L30,37 L30,31 L34,23 L43,14 L39,30 L46,31 L43,40 L36,46 Z",
            transform: CGAffineTransform(translationX: 518.0, y: 476.0)
        )
        
        shapes[14] = PrefectureShapeData(
            prefectureId: 14,
            pathData: "M10,0 L24,6 L28,11 L28,6 L30,6 L27,4 L30,2 L44,9 L40,13 L36,12 L39,16 L36,16 L36,23 L42,26 L38,30 L39,33 L35,33 L36,28 L33,24 L26,22 L15,25 L11,28 L12,34 L10,34 L4,30 L4,17 L0,17 L9,9 Z",
            transform: CGAffineTransform(translationX: 584.0, y: 656.0)
        )
        
        shapes[13] = PrefectureShapeData(
            prefectureId: 13,
            pathData: "M49,173 L49,178 L44,171 L49,173 Z M34,113 L32,115 L29,114 L31,111 L34,113 Z M11,104 L13,106 L11,107 L11,104 Z M18,98 L16,96 L18,92 L18,98 Z M22,75 L22,69 L26,70 L26,76 L22,75 Z M48,7 L49,12 L47,16 L41,15 L43,19 L39,20 L43,20 L43,23 L29,16 L26,18 L29,20 L27,20 L27,25 L23,20 L9,14 L4,11 L0,3 L3,0 L18,4 L23,8 L30,5 L30,9 L36,6 L40,7 L42,5 L48,7 Z",
            transform: CGAffineTransform(translationX: 585.0, y: 642.0)
        )
        
        shapes[12] = PrefectureShapeData(
            prefectureId: 12,
            pathData: "M5,29 L7,25 L6,20 L6,13 L0,0 L8,10 L19,15 L37,11 L37,8 L55,20 L55,24 L45,24 L34,35 L32,57 L19,61 L7,75 L0,71 L5,69 L3,66 L4,63 L3,58 L5,53 L1,49 L4,45 L7,46 L7,42 L13,39 L18,33 L11,26 L6,30 Z",
            transform: CGAffineTransform(translationX: 627.0, y: 629.0)
        )
        
        shapes[11] = PrefectureShapeData(
            prefectureId: 11,
            pathData: "M48,4 L49,5 L51,12 L54,11 L54,11 L60,24 L60,31 L54,29 L52,31 L48,30 L42,33 L42,29 L35,32 L30,28 L15,24 L12,27 L1,24 L0,19 L16,10 L21,0 L32,2 L38,6 Z",
            transform: CGAffineTransform(translationX: 573.0, y: 618.0)
        )
        
        shapes[10] = PrefectureShapeData(
            prefectureId: 10,
            pathData: "M64,52 L54,54 L48,50 L37,48 L32,58 L16,67 L12,65 L12,59 L9,56 L12,55 L10,49 L13,47 L12,41 L3,41 L0,36 L1,29 L6,25 L5,23 L14,20 L26,14 L26,11 L29,10 L28,5 L32,4 L34,0 L41,7 L49,9 L47,12 L50,14 L47,17 L46,26 L54,29 L48,42 L53,49 L62,48 Z",
            transform: CGAffineTransform(translationX: 557.0, y: 570.0)
        )
        
        shapes[9] = PrefectureShapeData(
            prefectureId: 9,
            pathData: "M19,60 L18,59 L16,55 L7,56 L2,49 L8,36 L0,33 L1,24 L4,21 L1,19 L3,16 L28,0 L40,3 L46,7 L47,13 L47,24 L48,27 L45,29 L47,39 L44,46 L33,48 L30,53 L27,53 L26,57 Z",
            transform: CGAffineTransform(translationX: 603.0, y: 563.0)
        )
        
        shapes[8] = PrefectureShapeData(
            prefectureId: 8,
            pathData: "M5,54 L5,54 L2,55 L0,48 L7,45 L8,41 L11,41 L14,36 L25,34 L28,27 L26,17 L29,15 L28,12 L28,1 L38,10 L44,4 L44,0 L54,5 L46,29 L47,35 L44,42 L46,52 L51,61 L49,63 L51,66 L52,62 L60,74 L42,62 L42,65 L24,69 L13,64 Z",
            transform: CGAffineTransform(translationX: 622.0, y: 575.0)
        )
        
        shapes[7] = PrefectureShapeData(
            prefectureId: 7,
            pathData: "M82,69 L72,64 L72,68 L66,74 L56,65 L55,59 L49,55 L37,52 L12,68 L4,66 L5,52 L0,47 L4,41 L2,37 L3,34 L12,33 L13,30 L21,30 L19,21 L28,11 L25,9 L32,11 L38,10 L40,14 L44,13 L47,15 L53,14 L56,10 L54,9 L55,0 L61,0 L65,4 L74,4 L75,10 L80,12 L79,10 L83,10 L83,4 L87,4 L93,18 L93,45 L91,61 Z",
            transform: CGAffineTransform(translationX: 594.0, y: 511.0)
        )
        
        shapes[6] = PrefectureShapeData(
            prefectureId: 6,
            pathData: "M14,1 L24,0 L28,5 L42,8 L44,13 L48,14 L53,22 L51,30 L48,30 L52,41 L45,53 L46,59 L43,65 L36,67 L37,72 L36,81 L38,82 L35,86 L29,87 L26,85 L22,86 L20,82 L14,83 L7,81 L4,76 L7,68 L7,60 L15,57 L17,53 L8,47 L8,40 L0,37 L13,14 Z",
            transform: CGAffineTransform(translationX: 612.0, y: 439.0)
        )
        
        shapes[5] = PrefectureShapeData(
            prefectureId: 5,
            pathData: "M54,97 L47,102 L43,101 L39,100 L37,95 L23,92 L19,87 L9,88 L11,78 L16,69 L17,47 L11,39 L3,42 L0,33 L6,36 L12,28 L15,19 L15,11 L10,6 L14,7 L17,3 L29,5 L32,2 L39,7 L42,5 L45,7 L55,0 L55,5 L60,5 L59,16 L55,21 L57,39 L52,40 L55,44 L52,48 L54,53 L50,59 L47,70 L55,83 L52,86 L55,91 Z",
            transform: CGAffineTransform(translationX: 617.0, y: 352.0)
        )
        
        shapes[4] = PrefectureShapeData(
            prefectureId: 4,
            pathData: "M33,70 L29,70 L29,76 L25,76 L26,78 L21,76 L20,70 L11,70 L7,66 L1,66 L0,61 L7,59 L10,53 L9,47 L16,35 L12,24 L15,24 L17,16 L12,8 L16,9 L23,4 L33,9 L41,8 L39,12 L45,16 L49,11 L55,14 L57,0 L64,1 L67,8 L62,5 L63,10 L59,14 L62,19 L60,17 L56,20 L60,22 L57,28 L61,28 L61,32 L58,30 L60,34 L57,35 L58,38 L61,37 L59,39 L61,41 L61,45 L57,43 L58,40 L55,41 L57,39 L56,37 L39,40 L36,43 L40,45 L35,46 L38,47 L32,57 L33,70 Z M43,41 L44,43 L42,43 L43,41 Z",
            transform: CGAffineTransform(translationX: 648.0, y: 445.0)
        )
        
        shapes[3] = PrefectureShapeData(
            prefectureId: 3,
            pathData: "M48,92 L41,91 L39,105 L33,102 L29,107 L23,103 L25,99 L17,100 L7,95 L8,89 L5,84 L8,81 L0,68 L3,57 L7,51 L5,46 L8,42 L5,38 L10,37 L8,19 L12,14 L16,15 L29,5 L31,8 L35,5 L40,7 L46,0 L54,11 L52,16 L57,19 L55,23 L61,28 L64,43 L62,53 L65,49 L66,54 L68,55 L62,60 L64,62 L67,59 L67,63 L63,63 L63,68 L60,69 L65,68 L60,71 L62,73 L60,75 L64,74 L58,81 L62,83 L57,83 L60,86 L57,86 L59,88 L53,89 L52,86 L54,91 L52,91 L52,94 L50,90 Z",
            transform: CGAffineTransform(translationX: 664.0, y: 354.0)
        )
        
        shapes[2] = PrefectureShapeData(
            prefectureId: 2,
            pathData: "M3,71 L3,63 L0,60 L6,51 L12,51 L18,47 L21,31 L17,27 L20,26 L21,19 L27,23 L31,20 L35,23 L37,38 L40,45 L46,41 L45,37 L47,33 L58,42 L61,39 L65,23 L61,16 L55,22 L41,25 L47,0 L64,11 L73,6 L71,37 L73,51 L77,62 L81,61 L86,67 L80,74 L75,72 L71,75 L69,72 L56,82 L52,81 L53,70 L48,70 L48,65 L38,72 L35,70 L32,72 L25,67 L22,70 L10,68 L7,72 Z",
            transform: CGAffineTransform(translationX: 624.0, y: 287.0)
        )
        
        shapes[1] = PrefectureShapeData(
            prefectureId: 1,
            pathData: "M4,240 L3,245 L0,246 L0,237 L6,235 L4,240 Z M33,261 L32,250 L28,243 L23,242 L21,237 L17,236 L15,231 L19,223 L17,212 L19,209 L28,207 L34,198 L37,202 L39,201 L43,192 L49,187 L39,173 L40,166 L47,164 L60,174 L71,171 L71,174 L78,177 L83,174 L89,165 L83,140 L86,135 L93,132 L97,126 L96,103 L100,95 L101,85 L98,67 L90,48 L93,39 L92,33 L94,36 L99,35 L105,28 L131,55 L139,68 L155,85 L184,104 L213,109 L214,113 L219,118 L238,118 L260,91 L262,96 L252,119 L252,129 L255,135 L265,138 L263,140 L264,137 L258,137 L263,149 L269,156 L273,157 L280,149 L287,148 L277,156 L275,163 L258,166 L256,172 L252,177 L247,177 L245,175 L246,173 L243,172 L240,178 L243,180 L228,181 L220,178 L205,186 L191,202 L182,216 L179,225 L180,240 L178,248 L164,237 L141,228 L113,211 L100,209 L103,206 L88,214 L72,230 L69,227 L73,227 L68,226 L66,220 L58,212 L47,213 L42,220 L39,230 L40,234 L52,242 L62,242 L71,254 L80,257 L82,260 L76,265 L72,267 L63,263 L60,265 L60,261 L57,260 L55,265 L48,269 L48,278 L40,282 L37,287 L30,284 L27,278 L28,269 L33,261 Z M71,48 L73,45 L77,47 L79,52 L75,55 L71,52 L71,48 Z M65,35 L65,33 L67,35 L66,45 L63,35 L65,35 Z M369,17 L367,13 L365,13 L363,17 L365,23 L364,26 L359,28 L357,35 L350,34 L351,41 L341,50 L341,54 L335,54 L335,56 L339,58 L339,62 L336,65 L332,64 L332,69 L329,66 L330,71 L327,78 L331,79 L336,70 L341,69 L346,59 L356,50 L358,40 L363,43 L369,41 L384,24 L397,15 L406,13 L407,10 L404,6 L407,2 L402,0 L396,2 L384,20 L373,22 L369,17 Z M290,99 L295,93 L303,91 L308,84 L311,85 L314,79 L304,82 L296,77 L293,79 L289,89 L280,104 L280,107 L266,122 L268,129 L273,128 L273,132 L274,119 L282,114 L283,109 L286,109 L287,102 L290,99 Z M322,125 L334,115 L329,113 L325,116 L326,117 L319,119 L319,123 L321,122 L322,125 Z M300,142 L304,137 L297,139 L300,142 Z M291,146 L293,143 L289,144 L291,146 Z",
            transform: CGAffineTransform(translationX: 602.0, y: 10.0)
        )
        

        return shapes
    }()

    /// 指定した都道府県IDの形状データを取得
    static func shape(for prefectureId: Int) -> PrefectureShapeData? {
        return allShapes[prefectureId]
    }
}
