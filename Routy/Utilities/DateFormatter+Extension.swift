//
//  DateFormatter+Extension.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation

extension DateFormatter {
    /// 日付フォーマット (例: 2024/12/01)
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 時刻フォーマット (例: 09:30)
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 日付時刻フォーマット (例: 2024/12/01 09:30)
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
