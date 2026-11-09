# D3 - Decyzje o magazynie i dostępności danych

## Tabela decyzji D3

| Dane | Magazyn docelowy | Dostępność  | Uzasadnienie |
|---|---|---|---|
| Access/refresh token | iOS Keychain  | Dostęp do danych pacjenta wymaga poprawnej sesji, a lokalny ekran może być dodatkowo blokowany przez `LocalAuthentication`.  | Keychain zapewnia bezpieczniejsze przechowywanie tokenów niż UserDefaults i ogranicza dostęp do nich innym aplikacjom. Tokeny muszą być dostępne wyłącznie w zakresie potrzebnym do utrzymania sesji użytkownika. |
| Dane znamion: typ, opis, notatki, lokalizacja na mapie ciała | Supabase PostgreSQL | Odczyt i zapis własnych danych po zalogowaniu, z ograniczeniem przez RLS; dermatolog może odczytać wskazane znamię wyłącznie przy aktywnym udostępnieniu. | PostgreSQL umożliwia centralne przechowywanie dokumentacji znamion, synchronizację między urządzeniami i egzekwowanie kontroli dostępu przez RLS. Ograniczenie lokalnego zapisu zmniejsza ryzyko ujawnienia danych medycznych na urządzeniu. |
| Fotografie znamion | Prywatny Supabase Storage `lesion-photos`; metadane i ścieżki w `public.lesion_photos` | Zdalny odczyt przez uwierzytelnionego właściciela lub dermatologa z aktywnym udostępnieniem, zgodnie z RLS | Prywatny Supabase Storage pozwala przechowywać fotografie poza urządzeniem oraz kontrolować ich pobieranie. Ograniczenie lokalnych kopii zmniejsza ryzyko nieuprawnionego dostępu do wrażliwych zdjęć. |
| Wybór sylwetki | `UserDefaults` / `@AppStorage` | Dostęp standardowy, bez sekretów | Wybór sylwetki jest zwykłym ustawieniem interfejsu, dlatego nie wymaga Keychain ani przechowywania na backendzie. UserDefaults zapewnia prosty sposób zachowania preferencji między uruchomieniami aplikacji. |
| Współrzędne geograficzne użytkownika | Pamięć operacyjna tylko podczas wyszukania | Bez trwałej retencji | Lokalizacja jest potrzebna jedynie podczas wyszukiwania pobliskich gabinetów. Przechowywanie jej w pamięci operacyjnej ogranicza zbieranie danych i zapobiega tworzeniu niepotrzebnej historii przemieszczania się użytkownika. |
| Pobrane dane konta i udostępnienia | **Pamięć procesu SwiftUI** dla UUID użytkownika, roli i wyniku zapytań; źródło danych: Supabase Auth, `public.profiles` oraz `public.lesion_shares`. | Dane pobierane dla aktualnej sesji; dostęp do rekordów i udostępnień sprawdzany przez RLS. Po wylogowaniu interfejs przechodzi na ekran logowania | Przechowywanie danych bieżącej sesji w pamięci operacyjnej ogranicza pozostawianie informacji o pacjentach na urządzeniu. Supabase pozostaje źródłem danych, a RLS zapewnia kontrolę dostępu do informacji i udostępnień. |
| Historia fotografii i ścieżki plików | Supabase PostgreSQL | Metadane i pliki dostępne tylko w granicach polityk RLS oraz aktywnych udostępnień. | Centralne przechowywanie historii w PostgreSQL umożliwia chronologiczne porządkowanie zdjęć, ich synchronizację i kontrolę dostępu. Ścieżki w bazie pozwalają powiązać metadane z plikami w prywatnym Storage bez zapisywania samych obrazów w PostgreSQL.
| Cache, tymczasowe pliki importu | `tmp` / `Library/Caches` tylko dla danych roboczych wymagających zapisu; aktualny przepływ pobierania JPG w części backend/iOS używa `Data` i `UIImage` w pamięci procesu. | Dane robocze powinny być usuwane po zakończeniu operacji | Dane robocze powinny być przechowywane tylko przez czas niezbędny do wykonania operacji. Ich usuwanie po zakończeniu przetwarzania ogranicza ryzyko pozostawienia wrażliwych danych na urządzeniu i ich przypadkowego uwzględnienia w kopiach zapasowych. |

## 

## 
