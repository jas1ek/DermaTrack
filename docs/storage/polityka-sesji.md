# D5 - Polityka sesji i danych lokalnych 

## Tabela D5 

| Zdarzenie | Co usuwamy (docelowo) | Gdzie (magazyn) | Co zostaje | Jak sprawdzimy |
|---|---|---|---|---|
| **Wylogowanie** | Access/refresh tokeny; stan użytkownika i prywatne cache; lokalne kopie znamion i zdjęć poprzedniego konta zgodnie z polityką retencji | Keychain, pamięć aplikacji, `UserDefaults` (stary `dermatrack.lesions.v1`), `Documents/LesionPhotos`, cache | Niewrażliwe ustawienia ogólne, jeśli nie są przypisane do konta | Weryfikacja usunięcia sesji po wylogowaniu i braku dostępu do danych poprzedniego konta. |
| **Reinstalacja** | Poprzednia sesja nie może zostać przywrócona z resztek Keychain; po instalacji wykrycie first-run i usunięcie poprzednich wpisów sesji (tylko przypisanych do aplikacji) | Keychain + znacznik nowej instalacji w kontenerze aplikacji | Zwykle brak lokalnych danych po czystej instalacji; ewentualne odzyskane dane serwerowe dopiero po nowym logowaniu | Test ponownej instalacji i sprawdzenie, czy wymagane jest logowanie. |
| **Wygaśnięcie sesji** | Nieaktualne tokeny i dane powiązane z użytkownikiem, jeśli nie uda się odnowienie sesji | Keychain, cache, stan pamięci | Publiczne i niewrażliwe ustawienia | Symulacja wygaśnięcia sesji i sprawdzenie blokady dostępu oraz ponownego logowania. |
| **Kopia zapasowa / nowe urządzenie** | Tokeny `ThisDeviceOnly` nie powinny przenosić się na inne urządzenie; odtwarzalne wrażliwe zdjęcia wykluczone zgodnie z polityką | Keychain, katalogi aplikacji i iCloud Backup | Preferencje niewrażliwe, jeśli są przeznaczone do migracji | Sprawdzenie odtworzonej kopii na innym urządzeniu pod kątem sesji i lokalnych zdjęć. |
| **Zmiana hasła na serwerze** | Lokalna sesja zgodnie z faktyczną polityką unieważniania tokenów backendu; cache po utracie autoryzacji | Keychain i stan sesji klienta | Publiczne/niewrażliwe ustawienia | Test zmiany hasła i unieważnienia sesji na drugim urządzeniu. |

