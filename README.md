<div align="center">

# 🚁 Quadcopter Simulator for MATLAB

### Configurable indoor quadcopter navigation & AprilTag simulation toolbox (formerly "AprilNav")
### حزمة أدوات قابلة للتخصيص لملاحة الكوادكوبتر الداخلية ومحاكاة AprilTag (باسمها السابق "AprilNav")

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a+-0076A8?logo=mathworks&logoColor=white)](https://www.mathworks.com/products/matlab.html)
[![Simulink](https://img.shields.io/badge/Simulink-required-orange?logo=mathworks&logoColor=white)](https://www.mathworks.com/products/simulink.html)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-00C896.svg)](LICENSE)

**Built by [Ahmed Darwish](mailto:eahmeddarwish@gmail.com)**

[⬅️ Original Project / المشروع الأصلي](https://github.com/cindyiskandar/Quadcopter_Control)

</div>

---

## 🌍 Overview | نظرة عامة

**[English]**
AprilNav is a rebuild of [cindyiskandar/Quadcopter_Control](https://github.com/cindyiskandar/Quadcopter_Control),
designed around one idea: **an indoor drone navigation toolbox is only
useful if it works in *your* space, not just the author's.** Upload your
own floor plan, place your own AprilTags, draw your own flight paths, and
AprilNav simulates a full quadcopter flight through it — no hardcoded
building, no MATLAB scripting required to get started.

**[العربية]**
AprilNav هو إعادة بناء لمشروع [cindyiskandar/Quadcopter_Control](https://github.com/cindyiskandar/Quadcopter_Control)،
قائمٌ على فكرةٍ واحدة: **حزمة أدوات ملاحة الدرون الداخلية لا تكون مفيدةً
إلا إذا عملت في *مساحتك أنت*، لا في مساحة المطوّر الأصلي فقط.** ارفع خريطة
مكانك الخاص، حدّد مواقع علامات AprilTag بنفسك، ارسم مسارات الطيران التي
تريدها، وسيقوم AprilNav بمحاكاة رحلة كوادكوبتر كاملة عبر هذا المكان — من
غير أي مبنى مُبرمَج مسبقًا، ومن غير الحاجة لكتابة كود MATLAB للبدء.

---

## ✨ What Changed vs. the Original Project | ما الذي تغيّر عن المشروع الأصلي

| | Original / الأصلي | AprilNav |
|---|---|---|
| Environment / البيئة | Fixed, hardcoded in the scripts | **JSON config per environment (`environments/<name>/config.json`)** — floor plan, scale, tags, paths, obstacles, all user-defined |
| Setup / الإعداد | Edit MATLAB constants by hand | **Interactive GUI wizard** (`AprilNav_EnvironmentSetup.m`) — upload a map, click to calibrate, place tags/paths/obstacles |
| AprilTag detection / كشف العلامات | Not present in the original control core | **Two modes**: proximity-based simulation (default, no extra toolbox) or real image-based detection via Computer Vision Toolbox's `readAprilTag` |
| Portability / قابلية النقل | One flight scenario, tied to the code | **Any number of environments**, switchable with `AprilNav_Env_SetActive(name)`, no code changes needed |
| Validation / التحقق | None | **CI-checked** `environments/*/config.json` (`scripts/validate_environments.py`) + `AprilNav_Check()` pre-flight sanity check |
| VR visualization / التصور ثلاثي الأبعاد | Building-specific VR scene | **Generic, neutral-floor VR scene** — works for any environment out of the box |

---

## 🎯 Why Environment-Driven, Not Hardcoded? | لماذا يعتمد على البيئة لا على كودٍ ثابت؟

**[English]**
A navigation toolbox that only flies through one specific room is a demo,
not a tool. Every value that could plausibly differ between two users —
floor-plan dimensions, tag placement, flight paths, vehicle mass and
inertia, even which detection mode to use — lives in one JSON file per
environment (`environments/<name>/config.json`), never in the MATLAB code
itself. Nothing under `matlab/` or `simulink/` should ever need to change
just because you're flying somewhere new; only your environment's config
does. This is checked automatically: `scripts/validate_environments.py`
runs in CI on every push and rejects a malformed environment before anyone
opens MATLAB.

**[العربية]**
حزمة ملاحةٍ لا تطير إلا في غرفةٍ واحدة بعينها هي مجرّد عرضٍ توضيحي، لا أداة
حقيقية. فكل قيمةٍ يُحتمل أن تختلف بين مستخدمَين — أبعاد المخطط الأرضي،
مواقع العلامات، مسارات الطيران، كتلة المركبة وعزم القصور الذاتي، بل وحتى
نمط الكشف المُستخدَم — موجودةٌ في ملفٍّ واحدٍ من نوع JSON لكل بيئة
(`environments/<name>/config.json`)، لا في كود MATLAB نفسه. لا ينبغي أبدًا
أن يتغيّر أي شيءٍ تحت مجلدَي `matlab/` أو `simulink/` لمجرّد أنك تطير في
مكانٍ جديد؛ فقط إعدادات بيئتك هي التي تتغيّر. ويُتحقَّق من هذا تلقائيًا:
يعمل `scripts/validate_environments.py` ضمن CI عند كل رفعٍ للكود، ويرفض أي
بيئةٍ غير صحيحة التركيب قبل أن يفتح أحدٌ برنامج MATLAB أصلًا.

### 🔬 Simulated Detection vs. Real Detection — Which Should You Trust? | الكشف المحاكى مقابل الكشف الحقيقي — أيّهما تثق به؟

**[English]**
`AprilNav_AprilTag_Sim.m` (the default) logs a detection whenever the
flown trajectory passes within a configurable radius of a tag you placed
in the environment editor — it is a **planning and testing aid**, not a
sensor. It will never miss a tag, never suffer from lighting or occlusion,
and never mis-ID a tag. That's useful for testing paths and coverage
before you fly anything real, but it should never be quoted as "detection
accuracy." `AprilNav_AprilTag_Vision.m` runs MATLAB's actual `readAprilTag`
on photos you provide — this is the only mode that tells you anything
about real-world detectability (lighting, distance, angle, tag size). The
two intentionally return the same `tagLog` shape so `AprilNav_Results.m`
can plot either one, but they are answering different questions and should
not be conflated.

**[العربية]**
تُسجِّل `AprilNav_AprilTag_Sim.m` (الوضع الافتراضي) حدث كشفٍ كلما مرّ
المسار المُحلَّق ضمن نطاقٍ قابلٍ للتهيئة من علامةٍ وضعتها في محرّر البيئة —
وهي **أداة تخطيطٍ واختبار**، لا مستشعرًا حقيقيًا. فهي لن تُفوّت علامةً
أبدًا، ولن تتأثر بالإضاءة أو الانسداد، ولن تُخطئ في تحديد هوية أي علامة.
وهذا مفيدٌ لاختبار المسارات والتغطية قبل أي طيرانٍ حقيقي، لكن لا ينبغي
أبدًا الاستشهاد به على أنه "دقة كشفٍ". أما `AprilNav_AprilTag_Vision.m`
فتُشغِّل دالة `readAprilTag` الفعلية من MATLAB على صورٍ تُزوِّدها أنت — وهذا
هو الوضع الوحيد الذي يخبرك بأي شيءٍ عن قابلية الكشف الفعلية في العالم
الحقيقي (الإضاءة، المسافة، الزاوية، حجم العلامة). يُعيد الوضعان عمدًا نفس
بنية `tagLog` كي تستطيع `AprilNav_Results.m` رسم أيٍّ منهما، لكنهما
يجيبان عن سؤالين مختلفين ولا ينبغي الخلط بينهما.

---

## 🏗️ Architecture | المعمارية

```
AprilNav/
├── LICENSE                        ← GPL-3.0
├── CREDITS.md                     ← Attribution & change log (GPL §5)
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── docs/
│   ├── ARCHITECTURE.md            ← How the pieces fit together
│   └── CONFIG_SCHEMA.md           ← Full environment config.json reference
├── scripts/
│   └── validate_environments.py   ← MATLAB-free CI check for environments/
├── .github/workflows/
│   └── validate-environments.yml
├── simulink/
│   ├── QuadcopterDynamics(.slx / _R2024a.slx)   ← Flight dynamics + PID control
│   ├── VR.wrl                     ← Generic 3D Animation scene (neutral floor)
│   └── body.wrl / propeller.wrl / asbWaypointMarker.wrl / asbQuadcopterTrajectory.wrl
├── matlab/
│   ├── Contents.m                 ← Standard MATLAB toolbox index
│   ├── AprilNav_Env_*.m           ← Environment CRUD (new/load/save/list/active)
│   ├── AprilNav_EnvironmentSetup.m   ← Interactive setup GUI
│   ├── AprilNav_RunMission.m      ← Flight driver (drives the Simulink model)
│   ├── AprilNav_AprilTag_Sim.m    ← Proximity-based tag detection (default)
│   ├── AprilNav_AprilTag_Vision.m ← Real image-based tag detection (optional)
│   ├── AprilNav_Results.m         ← Post-flight plots + tag annotations
│   ├── AprilNav_Animate3D.m       ← Animated 3D flight (native, any MATLAB, no toolbox)
│   └── AprilNav_Check.m           ← Pre-flight environment/toolbox check
└── environments/
    └── demo_room/                ← Ready-to-fly example environment
        ├── config.json
        ├── map.png
        └── preview.png
```

### The Pipeline, Visually | خط الأنابيب بصريًا

```
Upload floor plan      Place tags,         Fly simulation        Detect AprilTags       Review results
+ calibrate scale  →   paths, obstacles →  (Simulink model)  →   (sim or vision)    →    + optional 3D view
```

**Why one JSON schema per environment, not separate scripts per building:**
every field that could differ between two physical spaces — map image,
scale, origin, tags, obstacles, paths, even which Simulink model variant to
use — lives in `environments/<name>/config.json`
(`AprilNav_Env_Default.m` / `docs/CONFIG_SCHEMA.md`). Adding a new
environment never means touching `matlab/` or `simulink/`.

**لماذا مخطط JSON واحد لكل بيئة، لا نصوصًا برمجيةً منفصلةً لكل مبنى:**
كل حقلٍ يُحتمل أن يختلف بين مكانَين فعليَّين — صورة الخريطة، المقياس،
نقطة الأصل، العلامات، العوائق، المسارات، بل وحتى نسخة نموذج Simulink
المُستخدَمة — موجودٌ في `environments/<name>/config.json`
(`AprilNav_Env_Default.m` / `docs/CONFIG_SCHEMA.md`). إضافة بيئةٍ جديدة لا
تعني أبدًا لمس مجلدَي `matlab/` أو `simulink/`.

**Why certain variable names never change:**
a handful of MATLAB workspace variable names (`Xd`, `Yd`, `Zd`, `xp`,
`yp`, `Time`, `M`, `Index`) are referenced directly inside the compiled
`.slx` block XML of the underlying Simulink model — renaming them would
silently break the model with no MATLAB-level warning. Everything about
*how* those variables are computed (from environment config vs. any
hardcoded value) was freely rewritten; the names themselves were not.

**لماذا لا تتغيّر بعض أسماء المتغيرات أبدًا:**
عددٌ من أسماء متغيرات مساحة عمل MATLAB (`Xd`، `Yd`، `Zd`، `xp`، `yp`،
`Time`، `M`، `Index`) مُشار إليها مباشرةً داخل XML الخاص بكتلة نموذج
Simulink المُصرَّف (`.slx`) — وإعادة تسميتها ستُعطّل النموذج بصمتٍ دون أي
تحذيرٍ من MATLAB. أما *طريقة* حساب هذه المتغيرات (من إعدادات البيئة بدلًا
من أي قيمةٍ ثابتة) فقد أُعيدت كتابتها بالكامل بحرية؛ أما الأسماء نفسها
فبقيت كما هي.

---

## 🚀 Quick Start | البدء السريع

### 1. Add AprilNav to your MATLAB path | أضف AprilNav إلى مسار MATLAB

```matlab
addpath(genpath(AprilNav_Root()));
AprilNav_Check();   % pre-flight sanity check / فحص ما قبل الطيران
```

### 2. Build your own environment, or try the bundled demo | ابنِ بيئتك الخاصة، أو جرّب البيئة التجريبية المُرفَقة

```matlab
AprilNav_EnvironmentSetup();            % interactive GUI / واجهة تفاعلية
% -- or --
AprilNav_Env_SetActive('demo_room');    % use the bundled example / استخدم المثال المُرفَق
```

### 3. Fly a mission and review the results | نفّذ مهمة طيران وراجع النتائج

```matlab
AprilNav_UsePath('Out and back');   % stage a saved path / جهّز مسارًا محفوظًا
% open simulink/QuadcopterDynamics.slx, run it, then:
AprilNav_Results();       % plots + tag annotations / رسومات وتوضيحات العلامات
AprilNav_Animate3D();     % animated 3D flight, works on ANY MATLAB release,
                          % no toolbox required / تصور ثلاثي الأبعاد متحرك، يعمل
                          % على أي إصدار MATLAB، من غير أي توولبوكس إضافي
```

---

## 🌐 Environment Config | إعدادات البيئة

**[English]**
Every environment is one folder under `environments/<name>/` with a
`config.json` (schema: `docs/CONFIG_SCHEMA.md`) and a floor-plan image.
The bundled `demo_room` example ships with a placeholder floor plan, two
AprilTags, one obstacle, and one saved flight path ("Out and back") —
useful for verifying your setup before building a real environment:

**[العربية]**
كل بيئةٍ هي مجلدٌ واحدٌ تحت `environments/<name>/` يحتوي على `config.json`
(المخطط في `docs/CONFIG_SCHEMA.md`) وصورة مخططٍ أرضي. يأتي مثال
`demo_room` المُرفَق بمخططٍ أرضي تجريبي، وعلامتَي AprilTag، وعائقٍ واحد،
ومسار طيرانٍ محفوظٍ واحد ("Out and back") — مفيدٌ للتحقق من صحة إعدادك
قبل بناء بيئةٍ حقيقية:

![demo_room environment preview](environments/demo_room/preview.png)

---

## ⚠️ Honest Limitations | القيود الصادقة

**[English]**
- **Proximity-based detection is a planning aid, not a sensor model.** It
  cannot tell you whether a real camera would actually see a given tag
  from a given pose — only `AprilNav_AprilTag_Vision.m` (real photos) can.
- **Camera-pose-to-world-frame fusion is intentionally not implemented.**
  `AprilNav_AprilTag_Vision.m` returns detected tag IDs and estimated poses
  from photos, but does not fuse them into the flown trajectory — that
  fusion is application-specific and left to the user (see Roadmap).
- **Obstacles are a manual planning aid, not a collision system.**
  `AprilNav_Obs.m` plots obstacles for visual reference only; no automatic
  path validation or avoidance is performed against them.
- **`simulink/VR.wrl`'s VR Sink view is optional, cosmetic, and not
  guaranteed on every MATLAB release.** MathWorks has deprecated the
  classic VRML-based Simulink 3D Animation viewer in favor of an
  Unreal-Engine-based system; on some current releases the VR Sink
  viewer window does not open at all. Use `AprilNav_Animate3D()` instead
  for a 3D flight view guaranteed to work on any MATLAB release, old or
  new, with zero toolbox dependency. Everything else (flight, detection,
  results) already works without any VR toolbox.
- **This is a simulation/planning toolbox, not a certified flight
  controller.** Treat every result as a planning aid — always validate
  independently before flying real hardware.

**[العربية]**
- **الكشف القائم على القرب أداة تخطيطٍ، لا نموذج مستشعرٍ حقيقي.** فهو لا
  يستطيع إخبارك ما إذا كانت كاميرا حقيقية ستلتقط علامةً معيّنةً من وضعيةٍ
  معيّنة فعليًا — هذا ما يستطيع فعله `AprilNav_AprilTag_Vision.m` (الصور
  الحقيقية) فقط.
- **دمج وضعية الكاميرا مع الإطار المرجعي العالمي غير مُنفَّذٍ عمدًا.**
  تُعيد `AprilNav_AprilTag_Vision.m` معرّفات العلامات المكتشَفة ووضعياتٍ
  تقديرية من الصور، لكنها لا تدمجها في المسار المُحلَّق — هذا الدمج خاصٌّ
  بكل تطبيقٍ ومتروكٌ للمستخدم (انظر خطة التطوير).
- **العوائق أداة تخطيطٍ يدوية، لا نظام تصادم.** ترسم `AprilNav_Obs.m`
  العوائق لغرض المرجعية البصرية فقط؛ ولا يُجرى أي تحقّقٍ أو تجنّبٍ تلقائي
  للمسار حيالها.
- **عرض VR Sink في `simulink/VR.wrl` اختياري وتجميلي وغير مضمون على كل
  إصدارات MATLAB.** قامت MathWorks بإيقاف استخدام عارض Simulink 3D
  Animation القديم القائم على VRML لصالح نظامٍ جديد قائم على Unreal
  Engine؛ وفي بعض الإصدارات الحديثة لا تفتح نافذة VR Sink إطلاقًا. استخدم
  `AprilNav_Animate3D()` بدلًا منه للحصول على عرضٍ ثلاثي الأبعاد مضمون
  العمل على أي إصدار MATLAB، قديمًا كان أو حديثًا، من غير أي اعتمادٍ على
  توولبوكس. كل شيءٍ آخر (الطيران، الكشف، النتائج) يعمل بالفعل من غير أي
  توولبوكس VR.
- **هذه حزمة محاكاةٍ وتخطيطٍ، لا وحدة تحكم طيرانٍ معتمَدة.** تعامَل مع كل
  نتيجةٍ باعتبارها أداة تخطيطٍ — تحقّق دائمًا بشكلٍ مستقلٍّ قبل تشغيل أي
  عتادٍ حقيقي.

---

## 🗺️ Roadmap | خطة التطوير

- [x] Generic, user-configurable environment system (map, tags, paths, obstacles) / نظام بيئةٍ عام وقابل للتخصيص من المستخدم
- [x] Interactive GUI setup wizard / معالج إعدادٍ تفاعلي
- [x] Dual AprilTag detection modes (simulated + real vision) / وضعا كشفٍ لعلامات AprilTag (محاكاة + رؤية حقيقية)
- [x] CI-validated environment configs / إعدادات بيئةٍ يتحقق منها CI
- [x] Native-MATLAB animated 3D flight view, no toolbox required (`AprilNav_Animate3D`) / عرض طيرانٍ ثلاثي أبعادٍ متحرك بلا توولبوكس
- [ ] Multi-vehicle simulation (fleets sharing one environment) / محاكاة مركباتٍ متعددة
- [ ] ROS 2 bridge for hardware-in-the-loop testing / جسر ROS 2 للاختبار مع عتادٍ حقيقي
- [ ] Automatic camera-pose-to-world-frame fusion for vision mode / دمجٌ تلقائي لوضعية الكاميرا مع الإطار العالمي
- [ ] Headless/scripted batch mission runner / مُشغِّل مهامٍ مجمّعة دون واجهة

---

## ⚠️ Disclaimer | إخلاء المسؤولية

> **This project is a simulation and planning toolbox for research and
> educational purposes.** It is not a certified flight controller.
> Flying real drones involves real physical risk — always follow your
> local aviation regulations and validate any plan independently before
> flying real hardware.

> **هذا المشروع حزمة أدوات محاكاةٍ وتخطيطٍ لأغراضٍ بحثيةٍ وتعليمية.** وهو
> ليس وحدة تحكم طيرانٍ معتمَدة. ينطوي تشغيل الدرونات الحقيقية على مخاطرةٍ
> فعلية — التزم دائمًا بلوائح الطيران المحلية، وتحقّق من أي خطةٍ بشكلٍ
> مستقلٍّ قبل تشغيل أي عتادٍ حقيقي.

---

## 👤 Author | المطور

<div align="center">

**Ahmed Darwish**

*Electrical & Computer Engineer | Python · Arduino · Raspberry Pi · AI/ML*

[![Email](https://img.shields.io/badge/Email-eahmeddarwish%40gmail.com-EA4335?logo=gmail&logoColor=white)](mailto:eahmeddarwish@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-eahmeddarwish-181717?logo=github)](https://github.com/eahmeddarwish)

</div>

Original quadcopter dynamics, control, and VR visualization core by
**Cindy Iskandar** — see [`CREDITS.md`](CREDITS.md) for full attribution.

الأساس الأصلي لديناميكيات الكوادكوبتر والتحكم والتصور ثلاثي الأبعاد من
تطوير **Cindy Iskandar** — انظر [`CREDITS.md`](CREDITS.md) للتوثيق الكامل.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0** —
see [LICENSE](LICENSE) for details. As a derivative of a GPL-3.0 project,
any distribution of AprilNav (modified or not) must remain under GPL-3.0.

```
GPL-3.0 — free to use, modify, and distribute; derivative works must
remain under GPL-3.0, with modifications documented (see CREDITS.md).
```

---

<div align="center">

*Made with ❤️ by Ahmed Darwish*

</div>
