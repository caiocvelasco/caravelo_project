# Building the Source Files

This guide explains the structure of the three source files we created to mimic real Passenger Service System (PSS) outputs for Caravelo's data integration challenge.

## Mapping Source Files to Provided PDF Samples 

The structure and field names in the three source files (amadeus_pss_bookings.csv, sabre_pss_bookings.csv, vueling_api_bookings.json) are directly inspired by the variations observed in the five provided PDF samples. This mapping validates our approach to the core problem.

The fields and structures in the synthetic CSV and JSON files **were not invented arbitrarily**. Each was abstracted directly **from the real PDF samples provided**. 

For example:
- I saw “Fare Basis” and “Booking Status” in the WestJet and Qatar receipts,
- “PNR” and “Passenger Names” in the LATAM boarding passes,
- and nested passengers in the Vueling receipt. 

Our files simply re-express these real-world elements so that we can test ingestion and normalization pipelines. This demonstrates an awareness of how actual airline data flows differ by system type (legacy PSS vs. modern API) and keeps the project aligned with the integration challenges Caravelo described.

## The Interesting Complexity: Bookings vs. Passengers

A single booking (identified by a PNR or Record Locator) can contain multiple passengers. The source systems represent this relationship in fundamentally different ways, which is the central problem our data model must solve.

## 1. Amadeus PSS Bookings (`amadeus_pss_bookings.csv`)

**Inspired by**: `Data_sample_3.pdf` (WestJet) & `Data_sample_5.pdf` (Qatar Airways)
**Justification**: These documents exhibit classic, detailed **PSS** output patterns typical of systems like Amadeus and Sabre. They are rich in technical fields crucial for airline operations.
**Format:** CSV
**Passenger Relationship:** **One Row per Passenger**
**Characteristics:** Flat structure, classic PSS field names. If a booking has multiple passengers, each passenger gets their own row, and the booking information (like flight details) is repeated.

### Data Sample:
```csv
Record_Locator,Creation_Date,Pax_Type,Pax_Name,Dep_Stn,Arr_Stn,Flight_Num,Dep_Date,Booking_Sts,Fare_Basis,Tkt_Number
SAFPFF,2025-01-30 22:15:00,A,URB MILLANIONSHIRS MR,JED,DOH,QR1189,2025-01-30,HK,VJR3R1SQ,1572121634985
WADTAS,2024-06-10 09:00:00,A,URB MILLANIONSHIPS MR,YYC,MSP,WS6340,2024-06-19,OK,KO7D02EK,8382187552509
1AEPTX,2024-07-01 11:30:00,A,MSR SUZANNE LEE,MAD,CDG,IB1234,2024-07-15,HL,ECO123,9988776655443
```

### **Key Insight**: The `Pax_Name` field contains a single passenger's name. The unique Record_Locator links passengers from the same booking.

## Sabre PSS Bookings (`sabre_pss_bookings.csv`)

**Inspired by**: `Data_sample_4.pdf` (LATAM) & `Data_sample_2.pdf` (Ryanair Boarding Pass)
**Justification**: These samples show variations in field naming and the explicit representation of multiple passengers per booking, which we attribute to a different PSS (Sabre) for demonstration.
**Format**: CSV   
**Characteristics**: One row per passenger, different field names, same PNR repeats for multi-passenger bookings.

### Data Sample:
```csv
PNR,Create_Date_UTC,Passenger_Name,Frequent_Flyer_Number,Origin,Destination,Flight_Number,DepartureDate,Status,Class,TicketNumber
ABC123,2026-01-27 18:30:00,MADRID OCTUBRE,LY123456,MAD,SCL,LA705,2026-01-27,OK,ECONOMY,0452161785032
DEF456,2024-12-20 14:22:01,JOHN SMITH,BA789012,LHR,JFK,BA178,2024-12-24,HK,PREMIUM_ECONOMY,
DEF456,2024-12-20 14:22:01,JANE SMITH,BA789013,LHR,JFK,BA178,2024-12-24,HK,PREMIUM_ECONOMY,
GHI789,2024-10-05 08:15:47,ALICE DOE,,CDG,MIA,AF123,2024-10-20,XX,ECONOMY,1122334455667
```

### **Critical Insight**: The `PNR` DEF456 appears twice. This explicitly represents one booking containing two passengers (JOHN SMITH and JANE SMITH). This is a concrete example of the one-to-many relationship.

## 3. Vueling API Bookings (`vueling_api_bookings.json`)

**Inspired by**: `Data_sample_1.pdf` (Vueling) & Modern API Patterns
**Justification**: This sample is clearly from the airline's own consumer-facing systems, not a raw GDS output. It has a different structure focused on the customer experience.
**Format**: JSON   
**Characteristics**: Nested structure, one JSON object per booking, contains passenger arrays.

### Data Sample:

```json
[
  {
    "booking_reference": "ZJ2M8J",
    "created_at": "2025-02-23T10:15:00Z",
    "passengers": [ // Array of passengers
      { "name": "Indiana Jones", "type": "adult", "seat": "2E" },
      { "name": "Lindi Jones", "type": "child", "seat": "4F" }
    ],
    "flights": [ // Array of flight segments
      { "origin": "BCN", "destination": "SVQ", "flight_number": "VY2225" },
      { "origin": "SVQ", "destination": "BCN", "flight_number": "VY2215" }
    ],
    "price": { "total": 1433.88, "currency": "EUR" }
  }
]
```
### **Critical Insight**: The one-to-many relationship is nested within a single object in an array. This requires a different processing technique (flattening) compared to the CSVs.

## Summary Table of PDF to PSS Type Mapping

### Mapping of Provided PDF Samples to Source System Types

| PDF Sample | Airline | Inferred Source System Type | Inspired Source File | Key Identifying Characteristics |
| :--- | :--- | :--- | :--- | :--- |
| **Data_sample_1.pdf** | Vueling | **Airline Direct API** | `vueling_api_bookings.json` | Modern, commercial layout. Nested data structure with one booking reference (`ZJ2M8J`) containing multiple passengers and flights. Focus on ancillary services (seats, baggage). |
| **Data_sample_2.pdf** | Ryanair | **PSS (e.g., Sabre)** | `sabre_pss_bookings.csv` | Simple boarding pass. The same Record Locator (`HQIR7N`) is reused for the return flight, indicating a central PNR database. |
| **Data_sample_3.pdf** | WestJet | **PSS / GDS (e.g., Amadeus)** | `amadeus_pss_bookings.csv` | Classic "E-Ticket Receipt". Contains deep technical PSS fields: `Fare Basis`, `Booking Status`, a structured `Fare Calculation Line`, and detailed industry tax codes (US, XY, CA). |
| **Data_sample_4.pdf** | LATAM | **PSS (e.g., Sabre)** | `sabre_pss_bookings.csv` | Standard boarding pass. Uses common PSS field names like `N° DE TICKET` and `CLASE`. Flat data representation. |
| **Data_sample_5.pdf** | Qatar Airways | **PSS / GDS (e.g., Amadeus)** | `amadeus_pss_bookings.csv` | Detailed "Electronic Ticket Receipt". Contains advanced PSS data: `Fare Basis`, `Not Valid Before/After` dates, and a complex `Fare Calculation` line. |

### Concrete Field-by-Field Examples from the PDFs in Our Files

| Field in Our Source File | PDF Evidence (Sample & Quote) | Purpose of Mimicry |
| :--- | :--- | :--- |
| `PNR` / `Record_Locator` | `Data_sample_2.pdf`: "Referencia HQIR7N"<br>`Data_sample_5.pdf`: "Booking ref: 1A/SAFPFF" | To demonstrate different naming conventions for the same key entity (booking reference) across systems. |
| `Pax_Name` / `Passenger_Name` | `Data_sample_4.pdf`: "NOMBRE PASAJERO MADRID OCTUBRO"<br>`Data_sample_3.pdf`: "URB MILLANIONSHIPS MR" | To represent the core passenger identity entity across all systems. |
| `Fare_Basis` | `Data_sample_3.pdf`: "Fare Basis KO7D02EK"<br>`Data_sample_5.pdf`: "Fare basis: VJR3R1SQ" | To include critical revenue accounting and pricing data present in PSS outputs. |
| `Booking_Sts` / `Status` | `Data_sample_3.pdf`: "Booking Status OK TO FLY"<br>`Data_sample_5.pdf`: "Booking status: OK" | To represent the operational state of the booking segment. |
| `Tkt_Number` / `TicketNumber` | `Data_sample_4.pdf`: "Nº DE TICKET 0452161785032"<br>`Data_sample_3.pdf`: "TICKET NUMBER 8382187552509" | To include the key financial settlement identifier (e-ticket number). |
| `Frequent_Flyer_Number` | `Data_sample_3.pdf`: "FREQUENT FLYER NUMBER AF2102770783" | To demonstrate how auxiliary passenger data (loyalty program) is attached to a record. |
| `Origin` / `Dep_Stn` | `Data_sample_4.pdf`: "DESDE MADRID (MAD)"<br>`Data_sample_5.pdf`: "From JEDDAH KING ABDULAZIZ INTL" | To represent the standard departure airport code and name. |
| `Destination` / `Arr_Stn` | `Data_sample_4.pdf`: "HACIA SANTIAGO DE CHILE (SCL)"<br>`Data_sample_5.pdf`: "To DOHA HAMAD INTERNATIONAL" | To represent the standard arrival airport code and name. |
| `Flight_Num` / `Flight_Number` | `Data_sample_1.pdf`: "VY2225"<br>`Data_sample_4.pdf`: "VUELO LA 705" | To capture the operating flight number for the segment. |
| `Dep_Date` / `DepartureDate` | `Data_sample_5.pdf`: "Departure: 22:15 30Jan2025"<br>`Data_sample_4.pdf`: "SALIDA: 23:55 (27/JAN)" | To standardize the date-time format of departure across sources. |
| Nested `passengers[]` array | `Data_sample_1.pdf`: "Pasajeros: Indiana Jones, Lindi Jones" | To model the hierarchical relationship between a booking and its passengers, as used by modern APIs. |
| `Class` | `Data_sample_4.pdf`: "CLASE ECONOMY"<br>`Data_sample_5.pdf`: "Class: ECSFGCR2, V" | To capture the booking class, which determines fare rules and amenities. |

**Conclusion**: The generated CSV and JSON files are a valid abstraction of the real data.

