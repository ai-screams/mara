import Foundation

/// 커스텀 타이머 최근값(MRU) 순수 로직 — App의 PrefsStore가 저장/영속을 맡고,
/// "새 값을 어떻게 리스트에 반영하는가"라는 결정만 여기(Core, 테스트 가능)에 둔다.
///
/// 신뢰 경계: plist는 외부에서 조작될 수 있으므로 비유한(NaN/∞)·비양수 값은
/// 로드·삽입 양쪽에서 걸러낸다(2계층 완결).
public enum CustomDurationMRU {
    public static let defaultCap = 3

    /// 새 값을 맨 앞에 넣고 중복을 제거한 뒤 cap개로 자른다.
    /// 비유한·비양수 값은 무시하고 기존 리스트를 그대로 돌려준다.
    public static func inserting(_ seconds: TimeInterval,
                                 into list: [TimeInterval],
                                 cap: Int = defaultCap) -> [TimeInterval] {
        guard seconds.isFinite && seconds > 0 else { return list }
        var out = list.filter { $0 != seconds }
        out.insert(seconds, at: 0)
        return Array(out.prefix(max(0, cap)))
    }

    /// 로드 시 살균: 비유한·비양수를 버리고 cap개로 자른다(순서 보존).
    public static func sanitizing(_ list: [TimeInterval],
                                  cap: Int = defaultCap) -> [TimeInterval] {
        Array(list.filter { $0.isFinite && $0 > 0 }.prefix(max(0, cap)))
    }
}
