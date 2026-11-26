# STE100++ po polsku

Natywna polska wersja trybu STE100++. To nie jest tłumaczenie `../SKILL.md`. Zasady struktury są wspólne, a ten plik celuje w nawyki, które psują polski tekst techniczny: urzędowy styl, bezosobowe formy i łańcuchy imiesłowów. Wzorowane na ASD-STE100, bez certyfikatu i bez słownika ASD.

## 1. Zasady twarde

1. Najpierw odpowiedź. Pierwsze zdanie podaje wynik, decyzję albo odpowiedź.
2. Jedna myśl w jednym zdaniu. Jeden krok procedury to jedna czynność.
3. Strona czynna i nazwany wykonawca. „Skrypt usuwa plik”, a nie „plik zostaje usunięty”.
4. Warunek przed poleceniem. „Jeśli build się wywali, przeczytaj log.”
5. Ostrzeżenie: najpierw polecenie albo warunek, potem ryzyko. „Nie uruchamiaj tego na produkcji. Skrypt kasuje tabelę.”
6. Bez średników w prozie. Napisz dwa zdania.
7. Jedno słowo, jedno znaczenie w całym dokumencie. Nie mieszaj „sprawdź”, „zweryfikuj” i „zwaliduj” dla jednej czynności.
8. Czasownik zamiast rzeczownika odczasownikowego. „Sprawdź logi”, a nie „dokonaj weryfikacji logów”.
9. Nie zmieniaj kodu, komend, flag, ścieżek, identyfikatorów, cytowanych błędów, liczb ani siły zastrzeżeń.

## 2. Polskie choroby i lekarstwa

| Objaw | Źle | Dobrze |
|---|---|---|
| Strona bierna z „zostać” | Plik został zapisany przez instalator. | Instalator zapisał plik. |
| „Dokonać/przeprowadzić” + rzeczownik | Należy przeprowadzić restart usługi. | Zrestartuj usługę. |
| „Należy”, „trzeba”, „się” bez wykonawcy | Należy się upewnić, że port jest wolny. | Upewnij się, że port jest wolny. |
| Łańcuch imiesłowów na „-ąc”, „-wszy” | Uruchamiając skrypt, mając włączony cache, pamiętając o flagach… | Włącz cache. Uruchom skrypt z flagą `--clean`. |
| „W przypadku gdy”, „w sytuacji, gdy” | W przypadku gdy test nie przejdzie… | Jeśli test nie przejdzie… |
| „Celem”, „w celu” | W celu instalacji uruchom… | Żeby zainstalować, uruchom… |
| Ciąg dopełniaczy | ustawienie wartości limitu czasu połączenia puli | limit czasu dla puli połączeń |
| „Posiadać” zamiast „mieć” | Plik posiada uprawnienia 600. | Plik ma uprawnienia 600. |
| „Wykonać”, „realizować” jako wypełniacz | Wykonaj kopię zapasową bazy. | Zrób backup bazy. |
| Zbędne „jest” + przymiotnik | Wymaganym jest posiadanie klucza. | Potrzebny jest klucz. |
| Wata na otwarcie | Warto zauważyć, że… | Usuń. Zacznij od faktu. |
| Słowa reklamowe | kompleksowe, innowacyjne, nowoczesne, solidne rozwiązanie | Podaj liczbę, test albo platformę. |

## 3. Długość i rytm

- Do 15 słów w krokach procedury, do 20 w wyjaśnieniach, 25 to twardy limit. Polskie słowa są dłuższe niż angielskie, więc limity są niższe niż w wersji EN.
- Akapit to jeden temat i najwyżej 5 zdań.
- Wtrącenia i nawiasy rzadko. Długie wtrącenie to zwykle osobne zdanie.
- Myślnik rzadko. Myślnik zwykle ukrywa dwa zdania.

## 4. Tryb i forma zwracania się

- Instrukcje w trybie rozkazującym, 2. osoba liczby pojedynczej: „uruchom”, „sprawdź”, „usuń”.
- Bezokolicznik tylko w nagłówkach i etykietach przycisków: „Zainstaluj”, „Zapisz zmiany”.
- Jedna forma w całym dokumencie. Nie mieszaj „uruchom” z „należy uruchomić” ani z „uruchamiamy”.
- Rejestr użytkownika zostaje. Luźny tekst może być luźny, byle bez waty.

## 5. Terminy techniczne

- Angielskie terminy, które zespół używa na co dzień, zostają w oryginale: build, commit, branch, merge, deploy, cache, log.
- Odmieniaj je naturalnie i konsekwentnie: „w buildzie”, „po merge'u”, „commitów”.
- Identyfikatory nigdy się nie odmieniają: „w pliku `config.toml`”, a nie „w `config.tomlu`”.
- Nowe pojęcie zdefiniuj raz, przy pierwszym użyciu: „idempotentny (bezpieczny przy ponownym uruchomieniu)”.

## 6. Liczby, daty i jednostki

- Liczby cyframi, jednostka po spacji: `30 s`, `2 GiB`, `5 min`.
- Daty w ISO 8601: `2026-11-26`.
- Przecinek dziesiętny w prozie (`1,5 s`), kropka w kodzie i w wartościach konfiguracji (`1.5`).

## 7. Komunikaty błędów

- Co się stało, przyczyna (jeśli znana), co zrobić dalej.
- Bez przeprosin i bez obwiniania użytkownika.
- Przykład: `config.toml: nieznany klucz "colour" (linia 12). Użyj "color".`

## 8. Zastrzeżenia

- „Może”, „prawdopodobnie”, „chyba” zostają, gdy niepewność jest prawdziwa. Jedno zastrzeżenie na jedno twierdzenie.
- Usuń piętrowe zastrzeżenia: „mogłoby to potencjalnie ewentualnie pomóc” → „to może pomóc”.

## 9. Przykład

Przed:
> Warto zauważyć, że w przypadku gdy konfiguracja nie została poprawnie załadowana przez serwis, co może wynikać z błędnych uprawnień, należy dokonać weryfikacji logów; ewentualnie zrestartować kontener.

Po:
> Jeśli serwis nie wczytał konfiguracji, sprawdź logi. Najczęstsza przyczyna to złe uprawnienia do pliku. Jeśli logi nic nie pokazują, zrestartuj kontener.

Co się zmieniło: wata na otwarcie zniknęła, warunek stoi przed poleceniem, strona bierna przeszła w czynną, „dokonać weryfikacji” zmieniło się w „sprawdź”, średnik w dwa zdania, a każde zdanie niesie jedną myśl.

## 10. Autokontrola

1. Czy pierwsze zdanie daje odpowiedź?
2. Szukaj `;` w prozie. Podziel zdanie.
3. Szukaj „został”, „zostanie”, „zostały”. Nazwij wykonawcę.
4. Szukaj „dokonać”, „przeprowadzić”, „należy”, „w przypadku”, „w celu”. Zamień na czasownik albo „jeśli”.
5. Szukaj imiesłowów na „-ąc” i „-wszy”. Więcej niż jeden w zdaniu? Podziel.
6. Przeczytaj trzy najdłuższe zdania. Ponad limit? Podziel.
7. Czy zmieniłeś liczbę, identyfikator albo siłę zastrzeżenia? Cofnij.
