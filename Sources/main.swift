import Cocoa
import WebKit
import Carbon.HIToolbox
import UserNotifications

let home = URL(string: "https://backloggd.com")!
let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "Backloggd"
let bg = NSColor(red: 0.078, green: 0.094, blue: 0.11, alpha: 1)
let lightBg = NSColor(red: 0.957, green: 0.961, blue: 0.973, alpha: 1)
let lastPageKey = "lastPage"
// Backloggd is dark-only, so "day mode" inverts the page and flips media back to normal.
let lightCSS = """
html:root:root{color-scheme:light!important;
--primary-surface:#f4f5f8;--secondary-surface:#e6e9f0;--field-background-on-secondary:#d7dce7;--field-border-on-secondary:#b6bfd0;
--back-dropdown-divider:#c6cee0;--back-primary:#f4f5f8;--back-secondary:#e8ebf2;--back-highlight:#dfe3ee80;
--back-field:#dde2ee;--back-field-highlight:#6b7ba3;--back-interact:#5c74b0;--back-interact-secondary:#3f5bc4;
--back-pink:#e0467f;--back-pink-dk:#c92a68;--back-pink-lt:#f58fb8;--back-btn-toggled-text:#fff;
--back-text:#232a35;--back-text-review:#2a3547;--back-text-secondary:#5d6b7c;--back-text-disabled:#5d6b7c70;--back-link:#232a35;
--back-type-completed:#2f9a3b;--back-type-mastered:#7a479c;--back-type-abandoned:#d23a3a;--back-type-retired:#3d6ac0;--back-type-shelved:#cf7f1c;
--back-playing:#6a55d6;--back-wishlist:#3f86ad;--back-backlog:#b59a0a;
--back-field-background:#e9ecf4;--back-field-border:#c3cadb;--back-field-border-hover:#aab4cc;--back-field-placeholder:#4a5a7a70;--back-field-icon:#8793ad;--back-field-icon-secondary:#667390;}
body{background:#f4f5f8!important;color:#232a35}
img[src*='/logos/']{filter:invert(1) hue-rotate(180deg)!important}
.spinner>div{background-color:rgba(60,70,95,.7)!important}
.play-type-option h3,.play-type-option p{color:#1c222c!important}
#log-toggle-buttons label:not(.play-type-bkg) p{color:#2a3547!important}
.quick-access-bar .btn-play:hover i{color:#1c222c!important}
.quick-access-bar .btn-play-fill:not(.play-type-color) i,.quick-access-bar .log-btn.active:not(.play-type-color) i{color:#c92a68!important}
.tippy-box[data-theme~=backloggd-quick-access],.tippy-box[data-theme~=backloggd-helper],.tippy-box[data-theme~=backloggd-stats],.tippy-box[data-theme~=backloggd],.tippy-box[data-theme~=backloggd-badge]{color:#1c222c!important}
.quick-access-bar-more .btn-play-fill a,.quick-access-bar-more .toggled,.quick-access-bar-more .button-link,.quick-access-bar-more a{color:#1c222c!important}
.quick-access-bar-more .btn-play-fill a i,.quick-access-bar-more .toggled i{color:#c92a68!important}
.quick-access-bar-more .quick-journal,.tippy-box[data-theme~=backloggd-quick-access] .quick-journal{color:#1c222c!important}
h1,h2,h3,h4,h5,h6,.feed-title,a.name,#backloggd-total-stats p,footer p,.navbar-brand{color:#1c222c!important}
.filler-text,.game-rating p.text-center,[class*='game-title-section'] .col-auto.my-auto,.btn-nav{color:#5d6b7c!important}
.btn-nav.current{color:#1c222c!important}
.btn-link,.release-below,a.mx-2[href*='follow'],small:not([class]){color:#5d6b7c!important}
.btn-link.current,a.mr-2.current,a.game-title,#filters-title,.badge-title,.row.mx-0.title,.row.mx-0.title div{color:#1c222c!important}
label.fill-in-slim,label.fill-in{color:#4a5568!important}
input:checked + label.fill-in-slim,input:checked + label.fill-in{color:#fff!important}
label:not(.fill-in):not(.fill-in-slim){color:#232a35!important}
h1 .text-white,h2 .text-white,h3 .text-white{color:#1c222c!important}
.card-text em,.card-text strong,.review-body em,.review-body strong,[class*=review] em,[class*=review] strong{color:inherit!important}
.col-auto.px-0:not(:has(*)){color:#1c222c!important}
.modal-search .modal-content{background:rgba(255,255,255,.92)!important;box-shadow:0 30px 80px rgba(20,30,60,.25)!important}
.game-cover{box-shadow:0 2px 8px rgba(20,30,60,.18)!important}
.game-cover:hover{box-shadow:0 16px 32px rgba(20,30,60,.3)!important}
::-webkit-scrollbar-thumb{background:rgba(0,0,0,.28)!important;background-clip:padding-box!important}
::-webkit-scrollbar-thumb:hover{background:rgba(0,0,0,.42)!important;background-clip:padding-box!important}
"""

func isBackloggd(_ url: URL?) -> Bool {
    guard let h = url?.host else { return false }
    return h == "backloggd.com" || h.hasSuffix(".backloggd.com")
}

let modernCSS = """
html{scroll-behavior:smooth}
body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Helvetica Neue",Roboto,sans-serif!important;-webkit-font-smoothing:antialiased;letter-spacing:-.003em}
h1,h2,h3,h4{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",Roboto,sans-serif!important;letter-spacing:-.022em}
.card,.game-cover,.card-img{border-radius:12px!important}
.game-cover{box-shadow:0 2px 8px rgba(0,0,0,.35);transition:transform .22s cubic-bezier(.2,.8,.2,1),box-shadow .22s ease}
.game-cover:hover,.game-cover:focus-within{z-index:50!important}
.game-cover:hover{transform:translateY(-5px) scale(1.025);box-shadow:0 16px 32px rgba(0,0,0,.55)}
.btn{border-radius:10px!important;font-weight:600;transition:transform .15s ease,filter .15s ease,background-color .15s ease}
.btn:hover{filter:brightness(1.12)}.btn:active{transform:scale(.97)}
.form-control,.search-bar,input[type=search],input[type=text],textarea,select{border-radius:10px!important;border:1px solid rgba(255,255,255,.09)!important;transition:border-color .15s ease,box-shadow .15s ease}
.form-control:focus,.search-bar:focus,textarea:focus{border-color:rgba(120,180,255,.6)!important;box-shadow:0 0 0 3px rgba(120,180,255,.18)!important;outline:none}
.modal-content{border-radius:18px!important;border:1px solid rgba(255,255,255,.08)!important;box-shadow:0 30px 80px rgba(0,0,0,.6)!important}
.modal-search .modal-content{padding:1.25rem 1.5rem!important;background:rgba(30,33,40,.85)!important;-webkit-backdrop-filter:blur(24px) saturate(160%);backdrop-filter:blur(24px) saturate(160%)}
.modal-backdrop.show{opacity:.55!important;-webkit-backdrop-filter:blur(6px);backdrop-filter:blur(6px)}
#primary-nav{-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px)}
.dropdown-menu{border-radius:12px!important;border:1px solid rgba(255,255,255,.08)!important;box-shadow:0 14px 40px rgba(0,0,0,.5)!important}
a{transition:color .15s ease,opacity .15s ease}
::selection{background:rgba(120,180,255,.35)}
::-webkit-scrollbar{width:10px;height:10px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:rgba(255,255,255,.14);border-radius:10px;border:2px solid transparent;background-clip:padding-box}
::-webkit-scrollbar-thumb:hover{background:rgba(255,255,255,.26);background-clip:padding-box;border:2px solid transparent}
"""

let lightBulkCSS = """
.subtle-link:hover{color:#1c222c!important}
.secondary-link:hover{color:#1c222c!important}
.btn-link-small:hover,.btn-link:hover{color:#1c222c!important}
.backloggd-group.input-group .input-group-text i{color:#1c222c!important}
.backloggd-group .form-control:focus{color:#1c222c!important}
a:hover .backloggd-container p{color:#1c222c!important}
.collapse-text-more:hover{color:#1c222c!important}
#ncmp-consent-link button:hover{color:#1c222c!important}
a:hover{color:#1c222c!important}
.modal-search .search-btn:hover{color:#1c222c!important}
#landing-welcome-banner h1{color:#1c222c!important}
#landing-welcome-banner #backloggd-total-stats p{color:#1c222c!important}
#landing-about h2{color:#1c222c!important}
.landing-feature-showcase h2{color:#1c222c!important}
#humble-bundle .btn{color:#1c222c!important}
#main-title{color:#1c222c!important}
#profile-quickview #username a:hover,#widget-preview #username a:hover{color:#1c222c!important}
#profile-quickview #welcome-banner a:hover,#widget-preview #welcome-banner a:hover{color:#1c222c!important}
#coming-soon .coming-details .name{color:#1c222c!important}
.home-heading .home-more-link a:hover{color:#1c222c!important}
.news-article-v2 a{color:#1c222c!important}
.news-article-v2 .feed-title{color:#1c222c!important}
#past-articles .article a{color:#1c222c!important}
#past-articles .article .feed-title{color:#1c222c!important}
.coming-soon-title h1{color:#1c222c!important}
#search-type .btn-link:hover{color:#1c222c!important}
#search-results .result .game-name a{color:#1c222c!important}
#search-results .result h4{color:#1c222c!important}
#search-title h1{color:#1c222c!important}
.discovery-game-rating .game-rating{color:#1c222c!important}
.category-type-details summary:hover{color:#1c222c!important}
.filters-list .filter-radio-check,.filters-list .filter-radio-direction{color:#1c222c!important}
.filters-list input[type=radio]:checked+label{color:#1c222c!important}
.game-library-header{color:#1c222c!important}
.series-link.bg-transparent .series-title{color:#1c222c!important}
.game-cover .game-cover-storefront,.game-cover-img .game-cover-storefront{color:#1c222c!important}
.quick-access-bar-more .button-link:hover,.quick-access-bar-more a:hover{color:#1c222c!important}
.btn-play p,.log-btn p{color:#1c222c!important}
#log-toggle-buttons label:hover p,.btn-play:hover p{color:#1c222c!important}
#log-toggle-buttons label:focus p,.btn-play:focus p{color:#1c222c!important}
.user-collection-tile .collection-tile{color:#1c222c!important}
.game-card-meta .release-below{color:#1c222c!important}
.trailer-preview:hover{color:#1c222c!important}
.review-game-link:hover .review-game-name{color:#1c222c!important}
.review-title-nav .title-dropdown button:focus,.review-title-nav .title-dropdown button:hover{color:#1c222c!important}
.game-name a{color:#1c222c!important}
.review-details .game-status a:hover{color:#1c222c!important}
.comment .comment-body strong,.review-card .card-text strong{color:#1c222c!important}
.comment .comment-body a:hover,.review-card .card-text a:hover{color:#1c222c!important}
.review-card .game-status .play-type:hover,.review-card .review-platform:hover{color:#1c222c!important}
.review-card .username-link a:hover{color:#1c222c!important}
.review-card .comments-link:hover,.review-card .open-review-link:hover{color:#1c222c!important}
.review-card .review-more:hover{color:#1c222c!important}
#game-page-stats-container .number-text{color:#1c222c!important}
.avg-rating-mobile{color:#1c222c!important}
.playing-button.full:hover{color:#1c222c!important}
#game-profile a:hover .game-page-sidecard{color:#1c222c!important}
#game-profile .game-title-section{color:#1c222c!important}
.game-page-platform:hover{color:#1c222c!important}
#game-profile .time-section h3{color:#1c222c!important}
#game-profile #game-body .game-rating{color:#1c222c!important}
#game-profile .log-counters a:hover p{color:#1c222c!important}
#game-profile .log-counters .number-text{color:#1c222c!important}
#game-profile #game-body .col-cover .game-cover{color:#1c222c!important}
#game-reviews-back a:hover{color:#1c222c!important}
.backloggd-modal .modal-content .del-link:hover,.backloggd-modal .modal__content .del-link:hover{color:#1c222c!important}
.backloggd-modal .modal-content .modal-title,.backloggd-modal .modal__content .modal-title{color:#1c222c!important}
.backloggd-modal .modal-content .switch-modal-type:hover,.backloggd-modal .modal__content .switch-modal-type:hover{color:#1c222c!important}
.cancel-rating:hover{color:#1c222c!important}
#more-details p a:hover{color:#1c222c!important}
.category-tag p a:hover{color:#1c222c!important}
#widget-edit-modal .modal__container #widget-selector .widget-option:hover .widget-tags p{color:#1c222c!important}
.game-detail-row .game-title{color:#1c222c!important}
#filters-sidebar .filters-header #filters-title{color:#1c222c!important}
#filters-sidebar .section-header{color:#1c222c!important}
#activity_feed #activity-options input[type=checkbox]:checked+label,#activity_feed #activity-options label:hover,.activity-feed #activity-options input[type=checkbox]:checked+label,.activity-feed #activity-options label:hover{color:#1c222c!important}
#activity_feed .activity a:hover,.activity-feed .activity a:hover{color:#1c222c!important}
#activity_feed .activity a.game-title,.activity-feed .activity a.game-title{color:#1c222c!important}
.playdate-view .game-status:hover,.playthrough-view .game-status:hover{color:#1c222c!important}
.playdate-view h3,.playthrough-view h3{color:#1c222c!important}
.playdate-view .number-date,.playthrough-view .number-date{color:#1c222c!important}
#sort-direction-btn:hover{color:#1c222c!important}
.playthrough-detail-view h5.playthrough-title{color:#1c222c!important}
.game-log-view .log-editor-btn:hover{color:#1c222c!important}
.game-log-view #game-title a{color:#1c222c!important}
.game-log-view #game-status a:hover{color:#1c222c!important}
#display-filters-dropdown .dropdown-sort input[type=checkbox]:checked+.filter-toggable,#display-filters-dropdown .dropdown-sort input[type=radio]:checked+.filter-toggable,#nav-interactables .dropdown-sort input[type=checkbox]:checked+.filter-toggable,#nav-interactables .dropdown-sort input[type=radio]:checked+.filter-toggable,.nav-dropdown .dropdown-sort input[type=checkbox]:checked+.filter-toggable,.nav-dropdown .dropdown-sort input[type=radio]:checked+.filter-toggable{color:#1c222c!important}
#profile-nav a:hover{color:#1c222c!important}
#filter-tags a:hover{color:#1c222c!important}
#bio-body{color:#1c222c!important}
#profile-sidebar a:hover{color:#1c222c!important}
.journal_entry .game-name a,.user-game-log .game-name a{color:#1c222c!important}
.journal_entry .month-year-date h4,.user-game-log .month-year-date h4{color:#1c222c!important}
.journal_entry .date-entry,.user-game-log .date-entry{color:#1c222c!important}
.journal_entry .journal-quick-icons a:hover,.user-game-log .journal-quick-icons a:hover{color:#1c222c!important}
.journal_entry .journal-platform:hover,.journal_entry .journal-play-status a:hover,.journal_entry .journal-rating a:hover,.user-game-log .journal-platform:hover,.user-game-log .journal-play-status a:hover,.user-game-log .journal-rating a:hover{color:#1c222c!important}
#friends-header a:hover{color:#1c222c!important}
.user-reviews .rss-link:hover{color:#1c222c!important}
.user-reviews #review-likes{color:#1c222c!important}
#widget-edit-modal #widget-selector .widget-option:hover .quick-access-widget-title{color:#1c222c!important}
#settings-header h2{color:#1c222c!important}
#integrations-settings-forms h3,#patreon-error h2{color:#1c222c!important}
#password-reset-form .title{color:#1c222c!important}
#log-in .setting-nav:hover{color:#1c222c!important}
#log-in label{color:#1c222c!important}
.ip-suspect a:hover{color:#1c222c!important}
.backloggd-table a:hover{color:#1c222c!important}
#company-name{color:#1c222c!important}
#policy strong{color:#1c222c!important}
#policy .btn-link,#policy a{color:#1c222c!important}
#policy .btn-link:hover,#policy a:hover{color:#1c222c!important}
.documentation .table tbody tr,.documentation li,.documentation p{color:#1c222c!important}
.documentation h4,.documentation h5{color:#1c222c!important}
.about .title{color:#1c222c!important}
.about h2{color:#1c222c!important}
.about #privacy a:hover,.about #terms-of-service a:hover{color:#1c222c!important}
.player-card:hover{color:#1c222c!important}
#play-ratings a:hover .nametag{color:#1c222c!important}
#folder-selector #open-folders:hover{color:#1c222c!important}
#folder-selector #close-folders:hover{color:#1c222c!important}
.list-folder-link:hover{color:#1c222c!important}
#list-note-modal #list-entry-note{color:#1c222c!important}
#list-likes-counter,#list-likes-username{color:#1c222c!important}
.comments-link:hover{color:#1c222c!important}
.note-button:hover .button-link{color:#1c222c!important}
.draggable-list-entry .game-name{color:#1c222c!important}
.list-form .checkbox-label{color:#1c222c!important}
.detail-list-entry .list-entry-actions .button-link:hover{color:#1c222c!important}
.list-title{color:#1c222c!important}
#log-editor-game-cover:hover i{color:#1c222c!important}
.library-entry-editor .modal__container .library-entry-row p{color:#1c222c!important}
.circle-checkbox input+label:hover,.spoiler-check input+label:hover{color:#1c222c!important}
.circle-checkbox input:checked+label,.spoiler-check input:checked+label{color:#1c222c!important}
#journal-log-selection-modal .log-selection:hover h3{color:#1c222c!important}
#journal-game-modal #library-entries-container .library-entry:hover .platform-title,#log-editor-full #library-entries-container .library-entry:hover .platform-title,#log-editor-mobile #library-entries-container .library-entry:hover .platform-title,#playthrough-modal #library-entries-container .library-entry:hover .platform-title{color:#1c222c!important}
#journal-game-modal #expand-review-editor:hover,#log-editor-full #expand-review-editor:hover,#log-editor-mobile #expand-review-editor:hover,#playthrough-modal #expand-review-editor:hover{color:#1c222c!important}
#journal-game-modal .journal-section-nav #playthrough-selector+button:focus,#log-editor-full .journal-section-nav #playthrough-selector+button:focus,#log-editor-mobile .journal-section-nav #playthrough-selector+button:focus,#playthrough-modal .journal-section-nav #playthrough-selector+button:focus{color:#1c222c!important}
.log-selector-btn .playthrough-title{color:#1c222c!important}
#fav-company-nav .btn:hover,#series-progress-nav .btn:hover,#yearly-graph-nav .btn:hover{color:#1c222c!important}
.color-link{color:#1c222c!important}
#supporting-categories-title{color:#1c222c!important}
#play-date-editor-native .play-date-group-row label:not(.toggle-switch){color:#1c222c!important}
.library-group-toggle{color:#1c222c!important}
#friends-activity .played-date{color:#5d6b7c!important}
#search-type .btn-link{color:#5d6b7c!important}
.review-card .card-subtitle{color:#5d6b7c!important}
#game-profile #game-body .game-rating p{color:#5d6b7c!important}
#game-reviews-back a{color:#5d6b7c!important}
.fav-review .like-heart{color:#5d6b7c!important}
#friend-review-header p,#review-header p{color:#5d6b7c!important}
#no-reviews-found{color:#5d6b7c!important}
.backloggd-modal .modal-content .sub-title,.backloggd-modal .modal__content .sub-title{color:#5d6b7c!important}
.backloggd-modal .modal-content .switch-modal-type,.backloggd-modal .modal__content .switch-modal-type{color:#5d6b7c!important}
#friends-header a{color:#5d6b7c!important}
.friend-listing .user-content a{color:#5d6b7c!important}
#log-in #emailHelp{color:#5d6b7c!important}
.about #privacy a,.about #terms-of-service a{color:#5d6b7c!important}
#journal-game-modal #log-toggle-buttons label p,#log-editor-full #log-toggle-buttons label p,#log-editor-mobile #log-toggle-buttons label p,#playthrough-modal #log-toggle-buttons label p{color:#5d6b7c!important}
.journal-entries .journal-entry-row .stat-container-square,.journal-entries .journal-entry-row .play-date-preview-num,#playthrough-calendar .fc-daygrid-day-number,.status-card,.play-session-status.play-type,#user-stats h3,#user-stats #stats-title,#time-played-entries-header label,.time-played-table-header label{color:#1c222c!important}
.ranking.second{color:#fff!important}
.stat-value small{color:#fff!important}
"""

let appFeelCSS = """
html{overscroll-behavior:none}
body{-webkit-user-select:none}
.formatted-text,.card-text,.comment-body,#bio-body,.review-body,input,textarea,[contenteditable]{-webkit-user-select:text}
:focus:not(:focus-visible){outline:none!important}
*{-webkit-tap-highlight-color:transparent}
"""

// WKWebView with a context menu that feels native instead of Safari-like.
final class BLWebView: WKWebView {
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        let drop: Set<String> = ["WKMenuItemIdentifierInspectElement", "WKMenuItemIdentifierReload",
                                 "WKMenuItemIdentifierGoBack", "WKMenuItemIdentifierGoForward",
                                 "WKMenuItemIdentifierOpenImageInNewWindow",
                                 "WKMenuItemIdentifierOpenFrameInNewWindow", "WKMenuItemIdentifierDownloadLinkedFile"]
        for item in menu.items where drop.contains(item.identifier?.rawValue ?? "") { menu.removeItem(item) }
        for item in menu.items where item.identifier?.rawValue == "WKMenuItemIdentifierOpenLinkInNewWindow" { item.title = "Open Link in New Tab" }
        // tidy separators left behind
        while let first = menu.items.first, first.isSeparatorItem { menu.removeItem(first) }
        while let last = menu.items.last, last.isSeparatorItem { menu.removeItem(last) }
        var prevSeparator = false
        for item in menu.items { if item.isSeparatorItem && prevSeparator { menu.removeItem(item) } else { prevSeparator = item.isSeparatorItem } }
        if !menu.items.isEmpty { menu.addItem(.separator()) }
        let open = NSMenuItem(title: "Open Page in Browser", action: #selector(openPageInBrowser), keyEquivalent: "")
        let copy = NSMenuItem(title: "Copy Page Link", action: #selector(copyPageLink), keyEquivalent: "")
        open.target = self; copy.target = self
        menu.addItem(open); menu.addItem(copy)
    }
    @objc func openPageInBrowser() { if let u = url { NSWorkspace.shared.open(u) } }
    @objc func copyPageLink() {
        guard let u = url else { return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(u.absoluteString, forType: .string)
    }
}

// Slides and fades the page content in on every load and Turbo navigation.
let pageTransitionJS = """
(function () {
  if (window.__blAnim) return; window.__blAnim = true;
  if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const play = () => {
    const m = document.querySelector('main') || document.body;
    if (!m || !m.animate) return;
    m.animate([{ opacity: 0, transform: 'translateY(14px)' }, { opacity: 1, transform: 'translateY(0)' }],
              { duration: 340, easing: 'cubic-bezier(.2,.8,.2,1)' });
  };
  document.addEventListener('DOMContentLoaded', play);
  document.addEventListener('turbo:render', play);
})();
"""

// One browser tab: its own web view, sharing cookies and settings with the others.
final class Tab {
    let web: BLWebView
    var title = "New Tab"
    var pendingURL: URL?          // set for tabs restored at launch; loaded when first selected
    var progressObs: NSKeyValueObservation?
    var titleObs: NSKeyValueObservation?
    var loadingObs: NSKeyValueObservation?
    var loadedOnce = false        // has a real (non-challenge) page finished loading yet?
    init(web: BLWebView) { self.web = web }
}

// Branded loading screen shown instead of the site's own "checking your browser" page and during the first load.
final class LoadingOverlay: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subLabel = NSTextField(labelWithString: "")
    private let spinner = NSProgressIndicator()
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        isHidden = true
        alphaValue = 0
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .labelColor
        subLabel.font = .systemFont(ofSize: 13)
        subLabel.textColor = .secondaryLabelColor
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isIndeterminate = true
        let stack = NSStackView(views: [iconView, titleLabel, subLabel, spinner])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.setCustomSpacing(18, after: iconView)
        stack.setCustomSpacing(18, after: subLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    override func hitTest(_ point: NSPoint) -> NSView? { isHidden ? nil : self } // swallow clicks while visible
    func setBackground(_ color: NSColor) { layer?.backgroundColor = color.cgColor }
    func show(title: String, detail: String) {
        titleLabel.stringValue = title
        subLabel.stringValue = detail
        if isHidden {
            isHidden = false
            spinner.startAnimation(nil)
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0; pulse.toValue = 0.55; pulse.duration = 1.1
            pulse.autoreverses = true; pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            iconView.layer?.add(pulse, forKey: "pulse")
        }
        NSAnimationContext.runAnimationGroup { ctx in ctx.duration = 0.2; animator().alphaValue = 1 }
    }
    func hide() {
        guard !isHidden else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, self.alphaValue == 0 else { return }
            self.isHidden = true
            self.spinner.stopAnimation(nil)
            self.iconView.layer?.removeAnimation(forKey: "pulse")
        })
    }
}

final class TabItemView: NSView {
    let label = NSTextField(labelWithString: "")
    let closeButton = NSButton()
    var selected = false { didSet { needsDisplay = true; label.textColor = selected ? .labelColor : .secondaryLabelColor } }
    var onSelect: (() -> Void)?
    var onClose: (() -> Void)?
    override init(frame: NSRect) {
        super.init(frame: frame)
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 12)
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Tab")
        closeButton.imageScaling = .scaleProportionallyDown
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        addSubview(label); addSubview(closeButton)
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc func closeTapped() { onClose?() }
    override func layout() {
        super.layout()
        closeButton.frame = NSRect(x: 8, y: (bounds.height - 14) / 2, width: 14, height: 14)
        label.frame = NSRect(x: 26, y: (bounds.height - 16) / 2, width: max(bounds.width - 52, 0), height: 16)
    }
    override func draw(_ r: NSRect) {
        guard selected else { return }
        NSColor.labelColor.withAlphaComponent(0.12).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 3), xRadius: 6, yRadius: 6).fill()
    }
    override func mouseDown(with e: NSEvent) { onSelect?() }
    override func otherMouseUp(with e: NSEvent) { onClose?() }   // middle-click closes
}

final class TabBarView: NSView {
    var items: [TabItemView] = []
    let plus = NSButton()
    override init(frame: NSRect) {
        super.init(frame: frame)
        plus.isBordered = false
        plus.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Tab")
        plus.contentTintColor = .secondaryLabelColor
        addSubview(plus)
    }
    required init?(coder: NSCoder) { fatalError() }
    func update(titles: [String], selected: Int, onSelect: @escaping (Int) -> Void, onClose: @escaping (Int) -> Void) {
        items.forEach { $0.removeFromSuperview() }
        items = titles.enumerated().map { i, t in
            let v = TabItemView(frame: .zero)
            v.label.stringValue = t
            v.selected = i == selected
            v.onSelect = { onSelect(i) }
            v.onClose = { onClose(i) }
            addSubview(v)
            return v
        }
        needsLayout = true
    }
    override func layout() {
        super.layout()
        let n = CGFloat(max(items.count, 1))
        let w = min(220, (bounds.width - 44) / n)
        for (i, v) in items.enumerated() { v.frame = NSRect(x: 8 + CGFloat(i) * w, y: 0, width: w, height: bounds.height) }
        plus.frame = NSRect(x: 8 + CGFloat(items.count) * w + 4, y: (bounds.height - 22) / 2, width: 22, height: 22)
    }
    override func draw(_ r: NSRect) {
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
    }
}

struct SideItem {
    let title: String
    let symbol: String?
    let path: String?
    var action: String? = nil
    var isHeader: Bool { path == nil && action == nil }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuItemValidation, NSMenuDelegate, NSToolbarDelegate, NSToolbarItemValidation, UNUserNotificationCenterDelegate {
    var window: NSWindow!
    var split: NSSplitView!
    var sidebar: NSVisualEffectView!
    var table: NSTableView!
    var items: [SideItem] = []
    var syncingSelection = false
    var username: String? = UserDefaults.standard.string(forKey: "username")
    var statusItem: NSStatusItem!
    var container: NSView!
    var appearanceObs: NSKeyValueObservation?
    var theme: String { UserDefaults.standard.string(forKey: "theme") ?? "system" }
    var isLight: Bool {
        switch theme {
        case "light": return true
        case "dark": return false
        default: return NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        }
    }
    var sidebarWidth: NSLayoutConstraint!
    var sidebarCollapsed = UserDefaults.standard.bool(forKey: "sidebarCollapsed")
    var pendingQuickLog = false
    var userContent: WKUserContentController!
    var hotKeyRef: EventHotKeyRef?
    let cssOptions: [(tag: Int, key: String, title: String, css: String)] = [
        (1, "css.compact", "Compact Mode",
         "html{font-size:14px!important}#primary-nav{padding-top:.2rem!important;padding-bottom:.2rem!important}#main-gradient{height:160px!important}.footer{margin-top:1rem!important}"),
        (2, "css.wide", "Wide Layout",
         "@media(min-width:768px){main.main .container:not(.sidebar),header .container,footer .container{max-width:min(1600px,96vw)!important}}"),
        (3, "css.hidenav", "Hide Top Navigation Bar", "header{display:none!important}"),
        (4, "css.hidefooter", "Hide Footer", "footer.footer{display:none!important}"),
        (5, "css.modern", "Modern Look", modernCSS),
        (7, "css.appfeel", "App-Like Behaviour", appFeelCSS),
        (6, "css.noadgaps", "Remove Empty Ad Space", ".prosper-adframe:empty{display:none!important}.row:has(> .col > .prosper-adframe:empty){display:none!important}"),
    ]
    var customCSSURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Backloggd")
        return dir.appendingPathComponent("custom.css")
    }
    var web: BLWebView!
    var searchItem: NSSearchToolbarItem!
    var pollTimer: Timer?
    var lastUnread = UserDefaults.standard.bool(forKey: "lastUnread")
    var progress: NSProgressIndicator!
    var failedURL: URL?
    var tabs: [Tab] = []
    var selected = 0
    var baseConfig: WKWebViewConfiguration!
    var tabBar: TabBarView!
    var tabBarHeight: NSLayoutConstraint!
    var closedTabs: [URL] = []
    var keyMonitor: Any?
    var loadingOverlay: LoadingOverlay!
    var overlayGaveUp = false
    var overlayGeneration = 0

    func applicationDidFinishLaunching(_ n: Notification) {
        UserDefaults.standard.register(defaults: ["css.modern": true, "css.noadgaps": true, "css.appfeel": true])
        if !UserDefaults.standard.bool(forKey: "uiv2") { // native toolbar + sidebar replace the site's own nav and footer
            UserDefaults.standard.set(true, forKey: "css.hidenav")
            UserDefaults.standard.set(true, forKey: "css.hidefooter")
            UserDefaults.standard.set(true, forKey: "uiv2")
        }
        baseConfig = WKWebViewConfiguration()
        baseConfig.websiteDataStore = .default()
        userContent = WKUserContentController()
        baseConfig.userContentController = userContent
        tabBar = TabBarView(frame: .zero)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.plus.target = self
        tabBar.plus.action = #selector(newTabAction)
        tabBar.isHidden = true

        progress = NSProgressIndicator()
        progress.style = .bar
        progress.isIndeterminate = false
        progress.minValue = 0; progress.maxValue = 1
        progress.controlSize = .small
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false

        container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = bg.cgColor
        container.addSubview(tabBar)
        container.addSubview(progress)
        loadingOverlay = LoadingOverlay(frame: .zero)
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingOverlay)
        let guide = container.safeAreaLayoutGuide
        tabBarHeight = tabBar.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: guide.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tabBarHeight,
            progress.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            progress.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            loadingOverlay.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.title = "Backloggd"
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        let tb = NSToolbar(identifier: "main")
        tb.delegate = self
        tb.displayMode = .iconOnly
        tb.allowsUserCustomization = false
        window.toolbar = tb
        window.toolbarStyle = .unified
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
        window.backgroundColor = bg
        window.minSize = NSSize(width: 480, height: 360)
        sidebar = makeSidebar()
        split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(sidebar)
        split.addArrangedSubview(container)
        split.setHoldingPriority(.init(260), forSubviewAt: 0)
        sidebarWidth = sidebar.widthAnchor.constraint(equalToConstant: sidebarCollapsed ? 56 : 210)
        sidebarWidth.isActive = true
        sidebar.isHidden = UserDefaults.standard.bool(forKey: "sidebarHidden")
        window.contentView = split
        if !window.setFrameUsingName("MainWindow") { window.center() }
        window.setFrameAutosaveName("MainWindow")
        window.makeKeyAndOrderFront(nil)

        buildMenu()
        setUpStatusItem()
        registerHotKey()
        startNotifications()
        applyTheme()
        appearanceObs = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async { if self?.theme == "system" { self?.applyTheme() } }
        }
        restoreTabs()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self, e.window === self.window else { return e }
            let mods = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let chars = e.charactersIgnoringModifiers ?? ""
            if mods == .control && e.keyCode == 48 { self.nextTab(); return nil }                       // ⌃Tab
            if mods == [.control, .shift] && e.keyCode == 48 { self.prevTab(); return nil }             // ⌃⇧Tab
            if mods == [.command, .shift] && (chars == "]" || chars == "}") { self.nextTab(); return nil }
            if mods == [.command, .shift] && (chars == "[" || chars == "{") { self.prevTab(); return nil }
            if mods == .command, let d = Int(chars), (1...9).contains(d) {                             // ⌘1…⌘9
                self.selectTab(d == 9 ? self.tabs.count - 1 : min(d - 1, self.tabs.count - 1)); return nil
            }
            return e
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: Tabs
    func makeWebView() -> BLWebView {
        let w = BLWebView(frame: .zero, configuration: baseConfig)
        w.navigationDelegate = self
        w.uiDelegate = self
        w.allowsBackForwardNavigationGestures = true
        w.allowsMagnification = true
        w.setValue(false, forKey: "drawsBackground") // avoid white flash before first paint
        w.underPageBackgroundColor = isLight ? lightBg : bg
        w.translatesAutoresizingMaskIntoConstraints = false
        return w
    }

    @discardableResult
    func newTab(url: URL?, select: Bool = true, lazy: Bool = false, title: String? = nil) -> Tab {
        let t = Tab(web: makeWebView())
        if let title { t.title = title }
        t.progressObs = t.web.observe(\.estimatedProgress, options: [.new]) { [weak self, weak t] w, _ in
            DispatchQueue.main.async { if let self, let t, self.web === t.web { self.updateProgress(w) } }
        }
        t.titleObs = t.web.observe(\.title, options: [.new]) { [weak self, weak t] w, _ in
            DispatchQueue.main.async { if let self, let t, self.web === t.web { self.updateLoadingOverlay() } }
        }
        t.loadingObs = t.web.observe(\.isLoading, options: [.new]) { [weak self, weak t] w, _ in
            DispatchQueue.main.async { if let self, let t, self.web === t.web { self.updateLoadingOverlay() } }
        }
        tabs.append(t)
        if let url {
            if lazy { t.pendingURL = url } else { t.web.load(URLRequest(url: url)) }
        }
        if select { selectTab(tabs.count - 1) } else { refreshTabBar() }
        return t
    }

    func tab(for w: WKWebView) -> Tab? { tabs.first { $0.web === w } }

    func updateProgress(_ w: WKWebView) {
        progress.doubleValue = w.estimatedProgress
        progress.isHidden = !w.isLoading || w.estimatedProgress >= 1
    }

    func selectTab(_ i: Int) {
        guard tabs.indices.contains(i) else { return }
        web?.removeFromSuperview()
        selected = i
        let t = tabs[i]
        web = t.web
        container.addSubview(web, positioned: .below, relativeTo: progress)
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        web.alphaValue = 1
        if let u = t.pendingURL { t.pendingURL = nil; web.load(URLRequest(url: u)) }
        window.makeFirstResponder(web)
        updateProgress(web)
        if let u = web.url { syncSelection(u) } else { table?.deselectAll(nil) }
        refreshTabBar()
        refreshCSS()
        saveTabs()
        overlayGaveUp = false
        updateLoadingOverlay()
    }

    func refreshTabBar() {
        let show = tabs.count > 1
        tabBar.isHidden = !show
        tabBarHeight.constant = show ? 32 : 0
        tabBar.update(titles: tabs.map(\.title), selected: selected,
                      onSelect: { [weak self] i in self?.selectTab(i) },
                      onClose: { [weak self] i in self?.closeTab(i) })
    }

    func closeTab(_ i: Int) {
        guard tabs.indices.contains(i) else { return }
        if tabs.count == 1 { window.performClose(nil); return }
        let t = tabs.remove(at: i)
        if let u = t.web.url ?? t.pendingURL { closedTabs.append(u) }
        t.web.stopLoading()
        t.web.removeFromSuperview()
        t.progressObs = nil
        let wasCurrent = i == selected
        if i < selected { selected -= 1 }
        if wasCurrent { selectTab(min(i, tabs.count - 1)) } else { refreshTabBar(); saveTabs() }
    }

    func saveTabs() {
        let list = tabs.compactMap { t -> [String: String]? in
            guard let u = t.web.url ?? t.pendingURL, isBackloggd(u) else { return nil }
            return ["url": u.absoluteString, "title": t.title]
        }
        UserDefaults.standard.set(list, forKey: "tabs")
        UserDefaults.standard.set(selected, forKey: "tabIndex")
    }

    func restoreTabs() {
        let saved = (UserDefaults.standard.array(forKey: "tabs") as? [[String: String]] ?? []).compactMap { d -> (URL, String)? in
            guard let s = d["url"], let u = URL(string: s), isBackloggd(u) else { return nil }
            return (u, d["title"] ?? "")
        }
        if saved.isEmpty {
            var start = home
            if let s = UserDefaults.standard.string(forKey: lastPageKey), let u = URL(string: s), isBackloggd(u) { start = u }
            newTab(url: start)
        } else {
            for (u, t) in saved { newTab(url: u, select: false, lazy: true, title: t.isEmpty ? nil : t) }
            selectTab(min(max(UserDefaults.standard.integer(forKey: "tabIndex"), 0), tabs.count - 1))
        }
    }

    func cleanTitle(_ raw: String?) -> String {
        var t = raw ?? ""
        for suffix in [" | Backloggd", " - Backloggd"] where t.hasSuffix(suffix) { t = String(t.dropLast(suffix.count)) }
        return t.isEmpty ? "Backloggd" : t
    }

    @objc func newTabAction() { newTab(url: home); quickSearch() }
    @objc func closeCurrentTab() { closeTab(selected) }
    @objc func reopenClosedTab() { if let u = closedTabs.popLast() { newTab(url: u) } }
    @objc func nextTab() { if tabs.count > 1 { selectTab((selected + 1) % tabs.count) } }
    @objc func prevTab() { if tabs.count > 1 { selectTab((selected - 1 + tabs.count) % tabs.count) } }

    // MARK: Loading screen
    // The site sometimes shows an automatic "checking your browser" page before the real one. We leave it running
    // underneath (it must finish by itself) and just cover it with a branded screen. If it takes too long, or the
    // first load drags on, the cover is removed so nothing the page needs from you is ever hidden.
    func isChallengeTitle(_ t: String?) -> Bool {
        let s = (t ?? "").lowercased()
        return s.contains("establishing a secure connection") || s.contains("just a moment") || s.contains("security check")
    }

    func updateLoadingOverlay() {
        guard let w = web, loadingOverlay != nil else { return }
        let challenge = isChallengeTitle(w.title)
        let firstLoad = selected < tabs.count && !tabs[selected].loadedOnce && (w.isLoading || w.url == nil)
        if overlayGaveUp || !(challenge || firstLoad) {
            if !(challenge || firstLoad) { overlayGaveUp = false }
            loadingOverlay.hide()
            return
        }
        if challenge {
            loadingOverlay.show(title: "Securing your connection…", detail: "This happens automatically and only takes a moment.")
        } else {
            loadingOverlay.show(title: "Loading \(appName)…", detail: "Getting your games ready.")
        }
        overlayGeneration += 1
        let gen = overlayGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + (challenge ? 40 : 20)) { [weak self] in
            guard let self, self.overlayGeneration == gen else { return }
            self.overlayGaveUp = true
            self.loadingOverlay.hide()
        }
    }

    // MARK: Notifications
    func startNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        NSApp.dockTile.badgeLabel = lastUnread ? "●" : nil
        pollTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in self?.pollNotifications() }
    }

    // Looks at the bell on the site's home page. It doesn't open /notifications/, which would mark them as read.
    @objc func pollNotifications() {
        guard username != nil, web != nil else { return }
        let js = "return await fetch('/', {credentials: 'include', cache: 'no-store'}).then(r => r.text()).then(t => { const d = new DOMParser().parseFromString(t, 'text/html'); const b = d.querySelector('#nav-notification-bell'); return b ? !!b.querySelector('.notification-indicator') : null })"
        web.callAsyncJavaScript(js, arguments: [:], in: nil, in: .page) { [weak self] result in
            if case .success(let v) = result, let unread = v as? Bool { DispatchQueue.main.async { self?.setUnread(unread) } }
        }
    }

    func checkBellInPage() {
        let js = "(() => { const b = document.querySelector('#nav-notification-bell'); return b ? !!b.querySelector('.notification-indicator') : null })()"
        web.evaluateJavaScript(js) { [weak self] r, _ in
            if let unread = r as? Bool { self?.setUnread(unread) }
        }
    }

    func setUnread(_ unread: Bool) {
        NSApp.dockTile.badgeLabel = unread ? "●" : nil
        if unread && !lastUnread && !NSApp.isActive { postNotification(title: "Backloggd", body: "You have new notifications.") }
        lastUnread = unread
        UserDefaults.standard.set(unread, forKey: "lastUnread")
    }

    func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    @objc func sendTestNotification() { postNotification(title: "Backloggd", body: "Notifications are working.") }

    func userNotificationCenter(_ c: UNUserNotificationCenter, didReceive r: UNNotificationResponse, withCompletionHandler done: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.showWindow()
            if r.notification.request.content.body.contains("new notifications") {
                self.web.load(URLRequest(url: URL(string: "/notifications/", relativeTo: home)!.absoluteURL))
            }
        }
        done()
    }
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification, withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner, .sound])
    }

    // MARK: Toolbar
    func toolbarDefaultItemIdentifiers(_ t: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.init("bl.back"), .init("bl.forward"), .init("bl.reload"), .flexibleSpace, .init("bl.search"), .init("bl.log")]
    }
    func toolbarAllowedItemIdentifiers(_ t: NSToolbar) -> [NSToolbarItem.Identifier] { toolbarDefaultItemIdentifiers(t) }
    func toolbar(_ t: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier, willBeInsertedIntoToolbar: Bool) -> NSToolbarItem? {
        func button(_ symbol: String, _ label: String, _ action: Selector) -> NSToolbarItem {
            let item = NSToolbarItem(itemIdentifier: id)
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
            item.label = label; item.toolTip = label
            item.target = self; item.action = action
            item.isBordered = true
            return item
        }
        switch id.rawValue {
        case "bl.back": return button("chevron.left", "Back", #selector(goBack))
        case "bl.forward": return button("chevron.right", "Forward", #selector(goForward))
        case "bl.reload": return button("arrow.clockwise", "Reload", #selector(reload))
        case "bl.search":
            let item = NSSearchToolbarItem(itemIdentifier: id)
            item.searchField.placeholderString = "Search games"
            item.searchField.target = self
            item.searchField.action = #selector(toolbarSearchSubmit(_:))
            item.preferredWidthForSearchField = 240
            searchItem = item
            return item
        case "bl.log":
            let item = NSToolbarItem(itemIdentifier: id)
            let b = NSButton(title: "Log a Game", image: NSImage(systemSymbolName: "plus", accessibilityDescription: nil)!, target: self, action: #selector(quickLog))
            b.bezelStyle = .rounded
            b.imagePosition = .imageLeading
            b.bezelColor = NSColor(red: 0.79, green: 0.16, blue: 0.41, alpha: 1)
            b.attributedTitle = NSAttributedString(string: "Log a Game", attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 13, weight: .semibold)])
            b.contentTintColor = .white
            item.view = b
            item.label = "Log a Game"; item.toolTip = "Log a Game"
            return item
        default: return nil
        }
    }
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "bl.back": return web.canGoBack
        case "bl.forward": return web.canGoForward
        default: return true
        }
    }
    @objc func toolbarSearchSubmit(_ sender: NSSearchField) {
        let q = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty,
              let enc = q.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/?#"))),
              let url = URL(string: "https://backloggd.com/search/games/\(enc)/") else { return }
        web.load(URLRequest(url: url))
        window.makeFirstResponder(web)
    }

    // MARK: Sidebar
    func makeSidebar() -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        table = NSTableView()
        table.headerView = nil
        table.style = .sourceList
        table.rowSizeStyle = .default
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        let col = NSTableColumn(identifier: .init("c"))
        col.resizingMask = .autoresizingMask
        table.addTableColumn(col)
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: v.topAnchor, constant: 54), // clear the traffic lights
            scroll.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        rebuildItems()
        return v
    }

    func rebuildItems() {
        var list: [SideItem] = [
            .init(title: sidebarCollapsed ? "Expand" : "Collapse", symbol: "sidebar.left", path: nil, action: "toggle"),
            .init(title: "QUICK", symbol: nil, path: nil),
            .init(title: "Quick Log", symbol: "plus.circle.fill", path: nil, action: "quicklog"),
            .init(title: "Search", symbol: "magnifyingglass", path: nil, action: "search"),
            .init(title: isLight ? "Night Mode" : "Day Mode", symbol: isLight ? "moon.fill" : "sun.max.fill", path: nil, action: "theme"),
            .init(title: "DISCOVER", symbol: nil, path: nil),
            .init(title: "Home", symbol: "house", path: "/"),
            .init(title: "Popular", symbol: "flame", path: "/games/lib/popular/"),
            .init(title: "Trending", symbol: "chart.line.uptrend.xyaxis", path: "/games/lib/trending/"),
            .init(title: "Top Reviews", symbol: "text.bubble", path: "/reviews/trending/"),
            .init(title: "Upcoming", symbol: "calendar", path: "/upcoming-games/"),
        ]
        if let u = username {
            let base = "/u/\(u)/"
            list += [
                .init(title: "YOU", symbol: nil, path: nil),
                .init(title: "Profile", symbol: "person.crop.circle", path: base),
                .init(title: "Playing", symbol: "gamecontroller", path: base + "playing/"),
                .init(title: "Backlog", symbol: "tray.full", path: base + "backlog/"),
                .init(title: "Wishlist", symbol: "star", path: base + "wishlist/"),
                .init(title: "All Games", symbol: "square.grid.2x2", path: base + "games/"),
                .init(title: "Lists", symbol: "list.bullet", path: base + "lists/"),
                .init(title: "Reviews", symbol: "pencil.and.list.clipboard", path: base + "reviews/"),
                .init(title: "Journal", symbol: "book", path: base + "journal/"),
                .init(title: "Activity", symbol: "clock", path: base + "activity/"),
                .init(title: "Likes", symbol: "heart", path: base + "likes/"),
                .init(title: "ACCOUNT", symbol: nil, path: nil),
                .init(title: "Notifications", symbol: "bell", path: "/notifications/"),
                .init(title: "Settings", symbol: "gearshape", path: "/settings/"),
                .init(title: "Log Out", symbol: "rectangle.portrait.and.arrow.right", path: nil, action: "logout"),
            ]
        } else {
            list += [
                .init(title: "ACCOUNT", symbol: nil, path: nil),
                .init(title: "Sign In", symbol: "person.crop.circle", path: "/login/"),
                .init(title: "Register", symbol: "person.badge.plus", path: "/register/"),
            ]
        }
        items = list
        table?.reloadData()
        if let u = web?.url { syncSelection(u) }
    }

    func numberOfRows(in t: NSTableView) -> Int { items.count }
    func tableView(_ t: NSTableView, isGroupRow row: Int) -> Bool { items[row].isHeader }
    func tableView(_ t: NSTableView, shouldSelectRow row: Int) -> Bool { !items[row].isHeader }
    func tableView(_ t: NSTableView, viewFor col: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        let cell = NSTableCellView()
        let tf = NSTextField(labelWithString: item.title)
        tf.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(tf); cell.textField = tf
        cell.toolTip = item.isHeader ? nil : item.title
        if item.isHeader && sidebarCollapsed {
            tf.isHidden = true
        } else if item.isHeader {
            tf.font = .systemFont(ofSize: 11, weight: .semibold)
            tf.textColor = .secondaryLabelColor
            NSLayoutConstraint.activate([tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                                         tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor)])
        } else {
            let iv = NSImageView(image: NSImage(systemSymbolName: item.symbol ?? "circle", accessibilityDescription: nil) ?? NSImage())
            iv.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(iv); cell.imageView = iv
            if sidebarCollapsed {
                tf.isHidden = true
                NSLayoutConstraint.activate([
                    iv.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5),
                    iv.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    iv.widthAnchor.constraint(equalToConstant: 20),
                    iv.heightAnchor.constraint(equalToConstant: 20)])
            } else {
                NSLayoutConstraint.activate([
                    iv.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    iv.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    iv.widthAnchor.constraint(equalToConstant: 18),
                    tf.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: 6),
                    tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor)])
            }
        }
        return cell
    }
    func tableViewSelectionDidChange(_ n: Notification) {
        guard !syncingSelection, table.selectedRow >= 0 else { return }
        let item = items[table.selectedRow]
        if let action = item.action {
            switch action {
            case "toggle": toggleSidebar()
            case "quicklog": quickLog()
            case "search": quickSearch()
            case "theme": toggleDayNight()
            case "logout": logOut()
            default: break
            }
            if let u = web.url { syncSelection(u) } else { table.deselectAll(nil) }
            return
        }
        guard let path = item.path, let url = URL(string: path, relativeTo: home)?.absoluteURL else { return }
        web.load(URLRequest(url: url))
    }
    func tableView(_ t: NSTableView, heightOfRow row: Int) -> CGFloat {
        sidebarCollapsed && items[row].isHeader ? 8 : 26
    }
    func syncSelection(_ url: URL) {
        var path = url.path
        if !path.hasSuffix("/") { path += "/" }
        syncingSelection = true
        if let i = items.firstIndex(where: { $0.path == path }) {
            table.selectRowIndexes([i], byExtendingSelection: false)
        } else {
            table.deselectAll(nil)
        }
        syncingSelection = false
    }

    // Collapses the sidebar to an icon rail, or expands it again.
    @objc func toggleSidebar() {
        if sidebar.isHidden { toggleSidebarHidden(); return }
        sidebarCollapsed.toggle()
        UserDefaults.standard.set(sidebarCollapsed, forKey: "sidebarCollapsed")
        rebuildItems()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.allowsImplicitAnimation = true
            sidebarWidth.animator().constant = sidebarCollapsed ? 56 : 210
        }
    }

    @objc func toggleSidebarHidden() {
        sidebar.isHidden.toggle()
        UserDefaults.standard.set(sidebar.isHidden, forKey: "sidebarHidden")
    }

    // Opens the site's own "Log a Game" dialog on the current page.
    @objc func quickLog() {
        showWindow()
        let js = """
        (() => { if (!window.$ || !document.getElementById('add-a-game-modal')) return false;
          $('#add-a-game-modal').modal('show');
          setTimeout(() => document.getElementById('modal-game-search')?.focus(), 350);
          return true; })()
        """
        web.evaluateJavaScript(js) { [weak self] r, _ in
            guard let self, (r as? Bool) != true else { return }
            self.pendingQuickLog = true
            self.web.load(URLRequest(url: home))
        }
    }

    @objc func logOut() {
        let alert = NSAlert()
        alert.messageText = "Log out of Backloggd?"
        alert.addButton(withTitle: "Log Out"); alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let js = "(() => { const l = document.querySelector(\"a[href*='sign_out']\"); if (l) { l.click(); return true } return false })()"
        web.evaluateJavaScript(js) { [weak self] r, _ in
            if (r as? Bool) != true { self?.web.load(URLRequest(url: URL(string: "/users/sign_out/", relativeTo: home)!.absoluteURL)) }
        }
    }

    @objc func setUsername() {
        let alert = NSAlert()
        alert.messageText = "Your Backloggd username"
        alert.informativeText = "Used for the Profile, Backlog, Playing and Wishlist shortcuts. Leave blank to clear."
        alert.addButton(withTitle: "Save"); alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = username ?? ""
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let n = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        applyUsername(n.isEmpty ? nil : n)
    }

    func applyUsername(_ n: String?) {
        guard n != username else { return }
        username = n
        UserDefaults.standard.set(n, forKey: "username")
        rebuildItems()
    }

    // Reads the signed-in user's name from the site's own nav bar.
    func detectUsername() {
        let js = """
        (() => {
          const nav = document.querySelector('#primary-nav');
          if (!nav) return null;
          const hrefs = [...nav.querySelectorAll('a[href]')].map(x => x.getAttribute('href'));
          const p = hrefs.find(h => /^\\/u\\/[^\\/]+\\/?$/.test(h));
          if (p) return p.split('/')[2];
          return hrefs.includes('/login/') ? '' : null;
        })()
        """
        web.evaluateJavaScript(js) { [weak self] r, _ in
            if let n = r as? String { self?.applyUsername(n.isEmpty ? nil : n) }
        }
    }

    // MARK: Appearance (injected CSS)
    func composedCSS() -> String {
        var css = cssOptions.filter { UserDefaults.standard.bool(forKey: $0.key) }.map(\.css).joined(separator: "\n")
        if isLight { css += "\n" + lightCSS + "\n" + lightBulkCSS }
        if let user = try? String(contentsOf: customCSSURL, encoding: .utf8) { css += "\n" + user }
        return css
    }

    func refreshCSS() {
        let css = composedCSS()
        let literal = String(data: try! JSONSerialization.data(withJSONObject: [css]), encoding: .utf8)! // JSON array => safe JS string
        let js = """
        (() => { const css = \(literal)[0];
          let s = document.getElementById('bl-app-css');
          if (!s) { s = document.createElement('style'); s.id = 'bl-app-css'; (document.head || document.documentElement).appendChild(s); }
          s.textContent = css; })();
        """
        userContent.removeAllUserScripts()
        userContent.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        if UserDefaults.standard.bool(forKey: "css.appfeel") {
            userContent.addUserScript(WKUserScript(source: pageTransitionJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        for t in tabs { t.web.evaluateJavaScript(js, completionHandler: nil) }
    }

    func applyTheme() {
        switch theme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
        let color = isLight ? lightBg : bg
        window.backgroundColor = color
        container.layer?.backgroundColor = color.cgColor
        loadingOverlay?.setBackground(color)
        for t in tabs { t.web.underPageBackgroundColor = color }
        refreshCSS()
        rebuildItems()
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        UserDefaults.standard.set(["system", "light", "dark"][sender.tag - 11], forKey: "theme")
        applyTheme()
    }

    @objc func toggleDayNight() {
        UserDefaults.standard.set(isLight ? "dark" : "light", forKey: "theme")
        applyTheme()
    }

    @objc func toggleOption(_ sender: NSMenuItem) {
        guard let o = cssOptions.first(where: { $0.tag == sender.tag }) else { return }
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: o.key), forKey: o.key)
        refreshCSS()
    }

    @objc func editCustomCSS() {
        let url = customCSSURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let template = "/* Your own CSS for Backloggd. Saved changes apply when you switch back to the app. */\n\n"
            try? template.write(to: url, atomically: true, encoding: .utf8)
        }
        let textEdit = URL(fileURLWithPath: "/System/Applications/TextEdit.app")
        NSWorkspace.shared.open([url], withApplicationAt: textEdit, configuration: NSWorkspace.OpenConfiguration())
    }

    func applicationDidBecomeActive(_ n: Notification) { if web != nil { refreshCSS(); pollNotifications() } }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(setTheme(_:)) {
            item.state = ["system", "light", "dark"][item.tag - 11] == theme ? .on : .off
        }
        if item.action == #selector(toggleOption(_:)), let o = cssOptions.first(where: { $0.tag == item.tag }) {
            item.state = UserDefaults.standard.bool(forKey: o.key) ? .on : .off
        }
        return true
    }

    // MARK: Menu bar item + global hotkey
    func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: "Backloggd")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        func add(_ title: String, _ sel: Selector, key: String = "", tag: Int = 0) {
            let mi = NSMenuItem(title: title, action: sel, keyEquivalent: key)
            mi.target = self; mi.tag = tag; menu.addItem(mi)
        }
        add("Show / Hide \(appName)  (⌃⌥B)", #selector(toggleApp))
        menu.addItem(.separator())
        add("Quick Log", #selector(menuQuickLog))
        add(isLight ? "Switch to Night Mode" : "Switch to Day Mode", #selector(toggleDayNight))
        add("Search Games…", #selector(menuSearch))
        add("Home", #selector(menuOpen(_:)), tag: 0)
        if username != nil {
            menu.addItem(.separator())
            add("Playing", #selector(menuOpen(_:)), tag: 1)
            add("Backlog", #selector(menuOpen(_:)), tag: 2)
            add("Wishlist", #selector(menuOpen(_:)), tag: 3)
        } else {
            menu.addItem(.separator())
            add("Set Username for Quick Links…", #selector(menuSetUsername))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    func showWindow() {
        if window.isMiniaturized { window.deminiaturize(nil) }
        NSApp.unhide(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleApp() {
        if NSApp.isActive && window.isVisible && !NSApp.isHidden { NSApp.hide(nil) } else { showWindow() }
    }
    @objc func menuOpen(_ sender: NSMenuItem) {
        var path = "/"
        if let u = username {
            switch sender.tag { case 1: path = "/u/\(u)/playing/"; case 2: path = "/u/\(u)/backlog/"; case 3: path = "/u/\(u)/wishlist/"; default: break }
        }
        showWindow()
        web.load(URLRequest(url: URL(string: path, relativeTo: home)!.absoluteURL))
    }
    @objc func menuQuickLog() { quickLog() }
    @objc func menuSearch() { showWindow(); quickSearch() }
    @objc func menuSetUsername() { showWindow(); setUsername() }

    func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { delegate.toggleApp() }
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x42_4C_47_44), id: 1) // 'BLGD'
        RegisterEventHotKey(UInt32(kVK_ANSI_B), UInt32(controlKey | optionKey), id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    // MARK: Menu
    func buildMenu() {
        let main = NSMenu()
        func add(_ title: String, _ items: [(String, Selector?, String, Int)], target: AnyObject? = nil) {
            let item = NSMenuItem(); main.addItem(item)
            let m = NSMenu(title: title); item.submenu = m
            for (t, s, k, tag) in items {
                if t == "-" { m.addItem(.separator()); continue }
                let mi = NSMenuItem(title: t, action: s, keyEquivalent: k.lowercased())
                if k.first?.isUppercase == true { mi.keyEquivalentModifierMask = [.command, .shift] }
                if t.hasSuffix("Sidebar") { mi.keyEquivalentModifierMask = tag == 1 ? [.command, .control, .option] : [.command, .control] }
                mi.tag = tag; mi.target = target; m.addItem(mi)
            }
        }
        add("App", [("About \(appName)", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), "", 0),
                    ("-", nil, "", 0),
                    ("Hide \(appName)", #selector(NSApplication.hide(_:)), "h", 0),
                    ("Quit \(appName)", #selector(NSApplication.terminate(_:)), "q", 0)])
        add("File", [("New Tab", #selector(newTabAction), "t", 0),
                     ("Close Tab", #selector(closeCurrentTab), "w", 0),
                     ("Reopen Closed Tab", #selector(reopenClosedTab), "T", 0),
                     ("-", nil, "", 0),
                     ("Show Next Tab   ⌃⇥", #selector(nextTab), "", 0),
                     ("Show Previous Tab   ⌃⇧⇥", #selector(prevTab), "", 0)], target: self)
        add("Edit", [("Undo", Selector(("undo:")), "z", 0), ("Redo", Selector(("redo:")), "Z", 0), ("-", nil, "", 0),
                     ("Cut", #selector(NSText.cut(_:)), "x", 0), ("Copy", #selector(NSText.copy(_:)), "c", 0),
                     ("Paste", #selector(NSText.paste(_:)), "v", 0), ("Select All", #selector(NSText.selectAll(_:)), "a", 0),
                     ("-", nil, "", 0),
                     ("Find…", #selector(NSResponder.performTextFinderAction(_:)), "f", NSTextFinder.Action.showFindInterface.rawValue),
                     ("Find Next", #selector(NSResponder.performTextFinderAction(_:)), "g", NSTextFinder.Action.nextMatch.rawValue),
                     ("Find Previous", #selector(NSResponder.performTextFinderAction(_:)), "G", NSTextFinder.Action.previousMatch.rawValue)])
        add("Go", [("Quick Log", #selector(quickLog), "l", 0), ("Search Games…", #selector(quickSearch), "k", 0),
                   ("Check Notifications Now", #selector(pollNotifications), "", 0), ("Send Test Notification", #selector(sendTestNotification), "", 0),
                   ("Home", #selector(goHome), "d", 0), ("Back", #selector(goBack), "[", 0),
                   ("Forward", #selector(goForward), "]", 0), ("Reload", #selector(reload), "r", 0)], target: self)
        add("View", [("Collapse / Expand Sidebar", #selector(toggleSidebar), "s", 0),
                     ("Hide / Show Sidebar", #selector(toggleSidebarHidden), "s", 1),
                     ("Set Username…", #selector(setUsername), "", 0), ("-", nil, "", 0),
                     ("Compact Mode", #selector(toggleOption(_:)), "", 1),
                     ("Wide Layout", #selector(toggleOption(_:)), "", 2),
                     ("Hide Top Navigation Bar", #selector(toggleOption(_:)), "", 3),
                     ("Hide Footer", #selector(toggleOption(_:)), "", 4),
                     ("App-Like Behaviour", #selector(toggleOption(_:)), "", 7),
                     ("-", nil, "", 0),
                     ("Toggle Day / Night", #selector(toggleDayNight), "L", 0),
                     ("Theme: Match System", #selector(setTheme(_:)), "", 11),
                     ("Theme: Day (Light)", #selector(setTheme(_:)), "", 12),
                     ("Theme: Night (Dark)", #selector(setTheme(_:)), "", 13),
                     ("-", nil, "", 0),
                     ("Modern Look", #selector(toggleOption(_:)), "", 5),
                     ("Remove Empty Ad Space", #selector(toggleOption(_:)), "", 6),
                     ("Edit Custom CSS…", #selector(editCustomCSS), "", 0), ("-", nil, "", 0),
                     ("Zoom In", #selector(zoomIn), "+", 0), ("Zoom Out", #selector(zoomOut), "-", 0),
                     ("Actual Size", #selector(zoomReset), "0", 0)], target: self)
        add("Window", [("Minimize", #selector(NSWindow.miniaturize(_:)), "m", 0),
                       ("Zoom", #selector(NSWindow.zoom(_:)), "", 0)])
        NSApp.mainMenu = main
    }

    @objc func goHome() { web.load(URLRequest(url: home)) }
    @objc func goBack() { web.goBack() }
    @objc func goForward() { web.goForward() }
    @objc func reload() {
        if let u = failedURL { failedURL = nil; web.load(URLRequest(url: u)) } else { web.reload() }
    }
    @objc func zoomIn() { web.pageZoom = min(web.pageZoom + 0.1, 3) }
    @objc func zoomOut() { web.pageZoom = max(web.pageZoom - 0.1, 0.5) }
    @objc func zoomReset() { web.pageZoom = 1 }

    @objc func quickSearch() {
        showWindow()
        if let f = searchItem?.searchField { window.makeFirstResponder(f); f.selectText(nil) }
    }

    // MARK: Navigation
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = a.request.url, a.navigationType == .linkActivated, !isBackloggd(url),
           url.scheme == "http" || url.scheme == "https" || url.scheme == "mailto" {
            NSWorkspace.shared.open(url); decisionHandler(.cancel); return
        }
        // ⌘-click or middle-click opens a link in a new tab (⇧ to switch to it).
        if let url = a.request.url, isBackloggd(url), a.navigationType == .linkActivated,
           a.modifierFlags.contains(.command) || a.buttonNumber == 4 {
            decisionHandler(.cancel)
            newTab(url: url, select: a.modifierFlags.contains(.shift))
            return
        }
        if a.targetFrame?.isMainFrame == true, let url = a.request.url, isBackloggd(url),
           [.linkActivated, .formSubmitted].contains(a.navigationType) {
            func bare(_ u: URL?) -> String { var c = u.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }; c?.fragment = nil; return c?.string ?? "" }
            if bare(url) != bare(w.url) { // not just a #anchor jump
                NSAnimationContext.runAnimationGroup { ctx in ctx.duration = 0.12; w.animator().alphaValue = 0.55 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { if !w.isLoading { w.alphaValue = 1 } } // safety net
            }
        }
        decisionHandler(.allow)
    }
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration,
                 for a: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = a.request.url {
            if isBackloggd(url) { newTab(url: url) } else { NSWorkspace.shared.open(url) }
        }
        return nil
    }
    func webView(_ w: WKWebView, didStartProvisionalNavigation n: WKNavigation!) { failedURL = nil }
    // Fade the new page in instead of a hard cut.
    func webView(_ w: WKWebView, didCommit n: WKNavigation!) {
        if w !== web { w.alphaValue = 1; return } // background tab: no fade (animations don't run while detached)
        w.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            w.animator().alphaValue = 1
        }
    }
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let m = NSMenu()
        func add(_ title: String, _ sel: Selector, tag: Int = 0) {
            let mi = NSMenuItem(title: title, action: sel, keyEquivalent: ""); mi.target = self; mi.tag = tag; m.addItem(mi)
        }
        add("Quick Log", #selector(menuQuickLog))
        add("Search Games…", #selector(menuSearch))
        if username != nil {
            m.addItem(.separator())
            add("Playing", #selector(menuOpen(_:)), tag: 1)
            add("Backlog", #selector(menuOpen(_:)), tag: 2)
            add("Wishlist", #selector(menuOpen(_:)), tag: 3)
        }
        m.addItem(.separator())
        add(isLight ? "Switch to Night Mode" : "Switch to Day Mode", #selector(toggleDayNight))
        return m
    }
    // Session cookies (login without "Remember me") are normally dropped when the app quits.
    // Give them a 60-day expiry so WebKit writes them to disk and you stay signed in.
    func persistSessionCookies() {
        let store = web.configuration.websiteDataStore.httpCookieStore
        store.getAllCookies { cookies in
            for c in cookies where c.expiresDate == nil && c.domain.hasSuffix("backloggd.com") {
                var props = c.properties ?? [:]
                props.removeValue(forKey: .discard)
                props[.expires] = Date().addingTimeInterval(60 * 24 * 3600)
                if let kept = HTTPCookie(properties: props) { store.setCookie(kept) }
            }
        }
    }
    func applicationWillTerminate(_ n: Notification) { persistSessionCookies() }
    func applicationDidResignActive(_ n: Notification) { persistSessionCookies() }

    func webView(_ w: WKWebView, didFinish n: WKNavigation!) {
        if let t = tab(for: w) {
            t.title = cleanTitle(w.title); refreshTabBar(); saveTabs()
            if !isChallengeTitle(w.title) { t.loadedOnce = true }
        }
        if w === web { updateLoadingOverlay() }
        guard w === web else { return }
        if let u = w.url, isBackloggd(u) { UserDefaults.standard.set(u.absoluteString, forKey: lastPageKey) }
        var t = w.title ?? "Backloggd"
        for suffix in [" | Backloggd", " - Backloggd"] where t.hasSuffix(suffix) { t = String(t.dropLast(suffix.count)) }
        window.title = t.isEmpty ? "Backloggd" : t
        if let u = w.url { syncSelection(u) }
        persistSessionCookies()
        detectUsername()
        checkBellInPage()
        if pendingQuickLog { pendingQuickLog = false; quickLog() }
    }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { showError(e, w) }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { showError(e, w) }

    func showError(_ e: Error, _ w: WKWebView) {
        w.alphaValue = 1
        let ns = e as NSError
        if ns.code == NSURLErrorCancelled { return }
        // Plug-in/frame-load interrupted (e.g. a download) isn't a real failure.
        if ns.domain == "WebKitErrorDomain" { return }
        let target = (ns.userInfo[NSURLErrorFailingURLErrorKey] as? URL) ?? home
        failedURL = target
        let offline = ns.code == NSURLErrorNotConnectedToInternet || ns.code == NSURLErrorNetworkConnectionLost
        let title = offline ? "You're offline" : "Couldn't load the page"
        let esc = { (s: String) in s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: "\"", with: "&quot;") }
        let html = """
        <html><head><meta name="color-scheme" content="dark"><style>
        body{background:#141820;color:#e6e9ef;font:15px -apple-system,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;text-align:center}
        h1{font-size:22px;margin:0 0 8px} p{color:#8b93a3;margin:0 0 22px;max-width:380px}
        a{background:#5cccb8;color:#0d1117;text-decoration:none;font-weight:600;padding:9px 22px;border-radius:8px}
        </style></head><body><div><h1>\(title)</h1><p>\(esc(ns.localizedDescription))</p>
        <a href="\(esc(target.absoluteString))">Try again</a></div></body></html>
        """
        w.loadHTMLString(html, baseURL: target)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool { showWindow(); return true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
