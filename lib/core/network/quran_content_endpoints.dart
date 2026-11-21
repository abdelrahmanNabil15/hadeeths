/// hadeeths' own backend proxy for the Quran Foundation Content API
/// (docs/QURAN_API_REFACTOR_PLAN.md, section 2) -- never the Quran Foundation API directly.
/// The proxy, not this app, holds the OAuth client secret.
const quranContentBaseUrl =
    'https://hadeeths-quran-proxy.naabdo198.workers.dev/production/';

const translationEditionsPath = 'editions/translations';
const tafsirEditionsPath = 'editions/tafsirs';
const recitationEditionsPath = 'editions/recitations';
const translationSearchPath = 'search';

String translationByAyahPath(int editionId, String verseKey) =>
    'translations/$editionId/ayah/$verseKey';

String tafsirByAyahPath(int editionId, String verseKey) =>
    'tafsirs/$editionId/ayah/$verseKey';

String recitationByAyahPath(int recitationId, String verseKey) =>
    'recitations/$recitationId/ayah/$verseKey';

String qiraatMatrixPath(String verseKey) => 'qiraat/matrix/ayah/$verseKey';
