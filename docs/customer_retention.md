# Customer Retention

## Ziel

Ziel dieser Analyse ist es, das Wiederkaufsverhalten von Kunden über die Zeit zu untersuchen.

Konkret geht es um die Frage:

> Wie viele Kunden kaufen in den Monaten nach ihrer ersten Bestellung erneut?

---

## Datengrundlage

Verwendet werden relevante CSV-Dateien aus dem Olist E-Commerce Datensatz, insbesondere:

- Bestellungen  
- Kunden  

Berücksichtigt werden ausschließlich Bestellungen mit:

- `order_status = 'delivered'`

Begründung:

Nur ausgelieferte Bestellungen stellen tatsächlich abgeschlossene Käufe dar.  
Andere Status (z. B. „canceled“) würden das Bild verfälschen.

Analyseebene:

- `customer_unique_id` (repräsentiert den tatsächlichen Kunden über mehrere Bestellungen hinweg)

---