# AzShieldGCS

Pilotsuz hava vasitələri (PHA) üçün yer idarəetmə stansiyası.

> Bu README skeletdir — bölmələri öz məzmununuzla doldurun.

---

## Haqqında

<!-- Layihənin nə olduğunu, kimə xidmət etdiyini və əsas fərqləndirici
     xüsusiyyətlərini burada yazın. -->

## İmkanlar

<!-- Əsas funksionallıq siyahısı. Məsələn:
- Uçuş paneli və missiya planlayıcısı
- Çoxsaylı hava vasitəsi dəstəyi
- NTRIP/RTK korreksiya axını
- Video yayımı
-->

## Tələblər

| Komponent | Versiya |
|---|---|
| Qt | 6.8.3+ |
| CMake | 3.25+ |
| Kompilyator | MSVC 2022 (Windows), GCC/Clang (Linux) |

Video dəstəyi üçün GStreamer tələb olunur.

## Qurulma

```bash
git clone --recursive https://github.com/AykhanTa/AzSGCS.git
cd AzSGCS

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

Testlərlə birlikdə:

```bash
cmake -S . -B build -DQGC_BUILD_TESTING=ON
cmake --build build
cd build/test && ctest --output-on-failure
```

## Lisenziya

Bu layihə **Apache License 2.0** və **GPL-3.0** şərtləri altında paylanır.
Tam mətn üçün [LICENSE-APACHE](LICENSE-APACHE) və [LICENSE-GPL](LICENSE-GPL)
fayllarına baxın.

## İstinad

AzShieldGCS [QGroundControl](https://github.com/mavlink/qgroundcontrol) kod
bazası əsasında qurulmuşdur. QGroundControl Apache-2.0 və GPL-3.0 lisenziyaları
altında paylanır; həmin lisenziyalar və mənbə kodundakı müəllif hüququ
bildirişləri törəmə iş olaraq bu layihədə də saxlanılır.
