# Draft: permission request to HadeethEnc.com

**Status: draft, not sent.** The site shows no email address; use the *Contact Us* form on hadeethenc.com (name, email,
message). Fill the placeholders in `[brackets]` first. Send it yourself; keep their answer in writing and file it in this
repository's `docs/` (or wherever the project keeps legal records).

## Why this is needed

- The website lists seven conditions for downloading and republishing content; the API documentation lists two. Neither
  states a licence or says whether an app may keep a local copy. See `docs/PHASE0_REVISED_AUDIT.md`, section 7.
- Everything the app could add next (bookmarks that work offline, offline reading, a bundled starter set, share-as-image)
  stores or re-renders their content, so each depends on the answers below.

## Message (English)

**Subject:** Permission request: Android app "Prophetic Hadiths" (الأحاديث النبوية) using the HadeethEnc API

Assalamu alaikum wa rahmatullah,

I am the developer of a free Android app, *الأحاديث النبوية / Prophetic Hadiths* (Google Play: `com.hadeeths.eg`), which
shows hadiths from the HadeethEnc API in Arabic and English. The app has no ads, collects no personal data, and displays
the text exactly as the API returns it, with the line "Source: HadeethEnc.com" next to every hadith and in a "Sources and
rights" screen.

Your website's terms of use for republishing and the API documentation list different conditions, and I would like to be
sure I follow the correct ones. Could you please answer the following in writing?

1. **Which terms apply to apps that use the API**: the seven conditions on the website, or the two in the API documentation?
   Is there a licence name or a URL I should cite?
2. **Offline copies.** May the app store hadith content on the user's device so it can be read without a connection
   (a cache of what the user has opened, or a downloaded copy of the whole collection)? If yes, under what conditions?
3. **Bundled snapshot.** May a snapshot of the content be shipped inside the app package? If yes, how should it be versioned
   and how often must it be refreshed?
4. **Updates.** The API sends no version number, `ETag` or last-modified header. How should an app detect that a hadith,
   translation or grade was corrected, so that stale copies are replaced?
5. **Saved items.** May the app let users save hadiths (bookmarks) and keep the titles on the device?
6. **Sharing.** The app shares the hadith text with its grade, narrator and the source line. May it also create a share image
   (a picture of the text with the credit)?
7. **Search.** The app shows excerpts of search results with matched words highlighted, and may keep a separate
   normalized copy of the text only for searching (never displayed). Is that acceptable?
8. **Attribution.** Is "Source: HadeethEnc.com" sufficient, or is there wording or a logo you prefer? Should the publisher
   (the supervising organisation) be named as well?
9. **Usage limits.** Are there request-rate limits or a preferred way to identify the app (for example a User-Agent string)?
   Should a large catalogue download be done differently from normal browsing?
10. **Other languages.** The app currently uses Arabic and English. Are there conditions that differ by translation?

I will not change, add to, or remove from the content, and I will tell you if I find an error in a translation.

Jazakum Allahu khayran,
[Your name]
[Your email]
[Link to the Play Store page]

## الرسالة (بالعربية)

**الموضوع:** طلب إذن: تطبيق «الأحاديث النبوية» للأندرويد يستخدم واجهة HadeethEnc البرمجية

السلام عليكم ورحمة الله وبركاته،

أنا مطوّر تطبيق مجاني للأندرويد باسم «الأحاديث النبوية» (متجر Google Play: `com.hadeeths.eg`) يعرض الأحاديث من الواجهة البرمجية
لموقع HadeethEnc باللغتين العربية والإنجليزية. لا يحتوي التطبيق على إعلانات ولا يجمع أي بيانات شخصية، ويعرض النص كما تُرجعه
الواجهة دون تعديل، مع عبارة «المصدر: HadeethEnc.com» بجانب كل حديث وفي شاشة «المصادر والحقوق».

لاحظتُ أن شروط إعادة النشر في الموقع تختلف عن الشروط المذكورة في وثائق الواجهة البرمجية، وأودّ التأكد من الالتزام بالشروط الصحيحة.
فهل تتفضلون بالإجابة كتابةً عن الأسئلة الآتية؟

١. أي الشروط تنطبق على التطبيقات التي تستخدم الواجهة: الشروط السبعة في الموقع أم الشرطان في وثائق الواجهة؟ وهل توجد رخصة
   محددة أو رابط يمكنني الإشارة إليه؟
٢. هل يجوز للتطبيق حفظ محتوى الأحاديث على جهاز المستخدم لقراءته دون اتصال (ذاكرة مؤقتة لما فتحه المستخدم، أو نسخة محمّلة
   من المجموعة كاملة)؟ وبأي شروط؟
٣. هل يجوز تضمين نسخة من المحتوى داخل حزمة التطبيق؟ وكيف يُنظَّم إصدارها وكم مرة يجب تحديثها؟
٤. لا تُرسل الواجهة رقم إصدار ولا `ETag` ولا تاريخ تعديل. كيف يمكن للتطبيق معرفة أن حديثًا أو ترجمة أو درجة قد صُحّحت
   ليستبدل النسخ القديمة؟
٥. هل يجوز للتطبيق تمكين المستخدم من حفظ الأحاديث المفضّلة مع الاحتفاظ بعناوينها على الجهاز؟
٦. يشارك التطبيق نص الحديث مع درجته وراويه وسطر المصدر. هل يجوز إنشاء صورة للمشاركة تتضمن النص مع عبارة المصدر؟
٧. يعرض التطبيق مقتطفات من نتائج البحث مع تمييز الكلمات المطابقة، وقد يحتفظ بنسخة مُبسَّطة من النص للبحث فقط (لا تُعرض
   أبدًا). هل هذا مقبول؟
٨. هل عبارة «المصدر: HadeethEnc.com» كافية، أم توجد صيغة أو شعار تفضّلونه؟ وهل يلزم ذكر الجهة المشرفة؟
٩. هل توجد حدود لعدد الطلبات أو طريقة مفضّلة لتعريف التطبيق (مثل User-Agent)؟ وهل يختلف تنزيل مجموعة كبيرة عن التصفح العادي؟
١٠. يستخدم التطبيق حاليًّا العربية والإنجليزية. هل تختلف الشروط باختلاف الترجمة؟

ألتزم بعدم تعديل المحتوى أو الإضافة عليه أو الحذف منه، وسأبلغكم إن وجدتُ خطأً في ترجمة.

جزاكم الله خيرًا،
[الاسم]
[البريد الإلكتروني]
[رابط التطبيق في المتجر]

## After their answer

| Their answer | What it unlocks |
|---|---|
| Local copies allowed | Phase 4: offline cache with Drift, background refresh, offline search index |
| Only IDs may be kept | Bookmarks and recents that store ids and re-fetch when online |
| Share image allowed | A share-as-image card (credit baked into the picture) |
| No local copies | Keep the app online-only; document it in the store listing |
