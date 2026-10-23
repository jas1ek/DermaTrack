# DermaTrack - model zagrożeń STRIDE v1


**Trzy przepływy startowe:** F1 pacjent → P1 logowanie; F2 P1 ↔ P4 Supabase Auth (HTTPS/sesja); F3 P2 ↔ P5 PostgREST (metadane znamion/JWT, plan).



| ID | Element DFD / przepływ | STRIDE | Konkretny scenariusz zagrożenia | Prawd. | Wpływ | Ryzyko | Decyzja i działanie |
|---|---|---|---|---|---|---|---|
| T01 | E1 → P1 (F1) | S | Osoba posiadająca skradzione dane logowania podszywa się pod pacjenta. | Średnie | Wysoki | Wysokie | Zredukować: ochrona sesji, limity prób logowania, ponowna autoryzacja operacji wrażliwych. |
| T02 | P1 ↔ P4 (F2) | I | Token sesji trafia do logów lub jest przechowywany w niechronionym miejscu i umożliwia przejęcie konta. | Średnie | Wysoki | Wysokie | Zredukować: bezpieczny magazyn sesji, brak tokenów w logach, wylogowanie i unieważnianie sesji. |
| T03 | P1 ↔ P4 (F2) | T | Atakujący próbuje zmodyfikować odpowiedź lub żądanie uwierzytelnienia w niezaufanej sieci. | Niskie | Wysoki | Średnie | Zredukować: wymuszony HTTPS/TLS, brak wyłączenia weryfikacji certyfikatów. |
| T04 | P4 Supabase Auth | D | Automatyczne, liczne próby logowania ograniczają dostępność usługi. | Średnie | Średni | Średnie | Zredukować: limity żądań, kontrola błędów i ponowień. |
| T05 | P2 ↔ P5 (F3, plan) | E | Zmiana identyfikatora właściciela znamienia w żądaniu daje dostęp do cudzego rekordu przy błędnej polityce RLS. | Średnie | Wysoki | Wysokie | Zredukować: RLS na wszystkich tabelach, testy dostępu między kontami. |
| T06 | P2 ↔ P5 (F3, plan) | T | Klient wysyła zmodyfikowane pola znamienia lub identyfikator innego pacjenta. | Średnie | Wysoki | Wysokie | Zredukować: walidacja danych, kontrola własności po stronie bazy. |
| T07 | D1 lokalne UserDefaults | I | Historia i opisy znamion zapisane lokalnie zostają ujawnione z kopii danych lub na przejętym urządzeniu. | Średnie | Wysoki | Wysokie | Zredukować: ograniczyć lokalne dane medyczne, chronić pliki i cache, nie przechowywać zdjęć w UserDefaults. |
| T08 | E2 → P3 import zdjęć | T | Nieprawidłowy plik obrazu lub zmanipulowane metadane powodują błędne przypisanie zdjęcia do znamienia. | Średnie | Średni | Średnie | Zredukować: walidacja formatu/rozmiaru, jednoznaczne wiązanie zdjęcia z rekordem. |
| T09 | P3 → P6 (plan) | I | Zdjęcie znamienia jest przesyłane do publicznego zasobnika lub otrzymuje zbyt szeroki dostęp. | Średnie | Wysoki | Wysokie | Zredukować: prywatny bucket, polityki Storage, krótkotrwałe podpisane URL. |
| T10 | D3 Storage (plan) | D | Masowe wysyłanie dużych fotografii wyczerpuje limity i blokuje upload innych użytkowników. | Średnie | Średni | Średnie | Zredukować: limity rozmiaru/liczby plików i obsługa limitów API. |
| T11 | D2 PostgreSQL (plan udostępniania) | R | Brak historii nadania lub cofnięcia dostępu utrudnia ustalenie, kto udostępnił dokumentację dermatologowi. | Średnie | Średni | Średnie | Zredukować: rejestrować zdarzenia udostępnienia i cofnięcia bez logowania treści medycznych. |
| T12 | P5 / D2 (plan ról) | E | Dermatolog nadal odczytuje zdjęcia po wygaśnięciu lub cofnięciu uprawnienia. | Średnie | Wysoki | Wysokie | Zredukować: czasowe uprawnienia sprawdzane serwerowo przy każdym odczycie, testy cofnięcia dostępu. |
| T13 | P3 / ekran zdjęć | I | Podgląd zdjęcia pozostaje widoczny w przełączniku aplikacji po przejściu do tła. | Średnie | Średni | Średnie | Zredukować: maskowanie wrażliwego interfejsu po utracie aktywności. |
| T14 | P2 / D1 | T | Usunięcie lub zmiana danych lokalnych prowadzi do nieprawidłowej historii obserwacji. | Średnie | Średni | Średnie | Zredukować: walidacja integralności i kontrola zmian, bezpieczna migracja do backendu. |

