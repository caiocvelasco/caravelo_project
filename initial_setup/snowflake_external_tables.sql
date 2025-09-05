-- =======================================================
-- STEP 7 - External Tables for Each Source
-- =======================================================

-- Amadeus PSS Bookings (CSV)
CREATE OR REPLACE EXTERNAL TABLE CARAVELO_DB.RAW.AMADEUS_RAW
WITH LOCATION = @CARAVELO_DB.RAW.CSV_STAGE/amadeus
AUTO_REFRESH = FALSE
-- FILE_FORMAT = ( TYPE = CSV )
FILE_FORMAT = ( FORMAT_NAME = 'CARAVELO_DB.RAW.CSV_FORMAT' );

-- Sabre PSS Bookings (CSV)
CREATE OR REPLACE EXTERNAL TABLE CARAVELO_DB.RAW.SABRE_RAW
WITH LOCATION = @CARAVELO_DB.RAW.CSV_STAGE/sabre
AUTO_REFRESH = FALSE
FILE_FORMAT = ( FORMAT_NAME = 'CARAVELO_DB.RAW.CSV_FORMAT' );

-- Vueling API Bookings (JSON)
CREATE OR REPLACE EXTERNAL TABLE CARAVELO_DB.RAW.VUELING_RAW
WITH LOCATION = @CARAVELO_DB.RAW.JSON_STAGE/vueling
AUTO_REFRESH = FALSE
FILE_FORMAT = ( FORMAT_NAME = 'CARAVELO_DB.RAW.JSON_FORMAT' );

-- ========= CHECKING FILES ==========
-- Amadeus
SELECT * FROM CARAVELO_DB.RAW.AMADEUS_RAW LIMIT 5;
-- VALUE
-- {
--   "c1": "SAFPFF,2025-01-30 22:15:00,A,URB MILLANIONSHIRS MR,JED,DOH,QR1189,2025-01-30,HK,VJR3R1SQ,1572121634985"
-- }
-- {
--   "c1": "WADTAS,2024-06-10 09:00:00,A,URB MILLANIONSHIPS MR,YYC,MSP,WS6340,2024-06-19,OK,KO7D02EK,8382187552509"
-- }
-- {
--   "c1": "1AEPTX,2024-07-01 11:30:00,A,MSR SUZANNE LEE,MAD,CDG,IB1234,2024-07-15,HL,ECO123,9988776655443"
-- }


-- Sabre
SELECT * FROM CARAVELO_DB.RAW.SABRE_RAW LIMIT 5;
-- VALUE
-- {
--   "c1": "ABC123,2026-01-27 18:30:00,MADRID OCTUBRE,LY123456,MAD,SCL,LA705,2026-01-27,OK,ECONOMY,0452161785032"
-- }
-- {
--   "c1": "DEF456,2024-12-20 14:22:01,JOHN SMITH,BA789012,LHR,JFK,BA178,2024-12-24,HK,PREMIUM_ECONOMY,"
-- }
-- {
--   "c1": "DEF456,2024-12-20 14:22:01,JANE SMITH,BA789013,LHR,JFK,BA178,2024-12-24,HK,PREMIUM_ECONOMY,"
-- }
-- {
--   "c1": "GHI789,2024-10-05 08:15:47,ALICE DOE,,CDG,MIA,AF123,2024-10-20,XX,ECONOMY,1122334455667"
-- }

-- Vueling JSON
SELECT * FROM CARAVELO_DB.RAW.VUELING_RAW LIMIT 5;
-- VALUE
-- [
--   {
--     "booking_reference": "ZJ2M8J",
--     "created_at": "2025-02-23T10:15:00Z",
--     "flights": [
--       {
--         "departure_date": "2025-06-21",
--         "destination": "SVQ",
--         "flight_number": "VY2225",
--         "origin": "BCN"
--       },
--       {
--         "departure_date": "2025-06-25",
--         "destination": "BCN",
--         "flight_number": "VY2215",
--         "origin": "SVQ"
--       }
--     ],
--     "passengers": [
--       {
--         "name": "Indiana Jones",
--         "seat": "2E",
--         "type": "adult"
--       },
--       {
--         "name": "Lindi Jones",
--         "seat": "4F",
--         "type": "child"
--       }
--     ],
--     "price": {
--       "currency": "EUR",
--       "total": 1433.88
--     }
--   },
--   {
--     "booking_reference": "9H7J2K",
--     "created_at": "2024-11-11T09:30:00Z",
--     "flights": [
--       {
--         "departure_date": "2016-04-15",
--         "destination": "BCN",
--         "flight_number": "FR6333",
--         "origin": "SCQ"
--       }
--     ],
--     "passengers": [
--       {
--         "name": "Angel Cancelo Márquez",
--         "seat": "05F",
--         "type": "adult"
--       }
--     ],
--     "price": {
--       "currency": "EUR",
--       "total": 49.99
--     }
--   },
--   {
--     "booking_reference": "L1M3N5",
--     "created_at": "2024-08-01T16:45:00Z",
--     "flights": [
--       {
--         "departure_date": "2024-09-10",
--         "destination": "LIS",
--         "flight_number": "VY7890",
--         "origin": "FRA"
--       }
--     ],
--     "passengers": [
--       {
--         "name": "Tech Demo User",
--         "seat": "10A",
--         "type": "adult"
--       }
--     ],
--     "price": {
--       "currency": "EUR",
--       "total": 129.5
--     }
--   }
-- ]

-- =======================================================
-- BUILDING FLATTENED VIEW IN RAW FROM EXTERNAL TABLES
-- =======================================================

CREATE OR REPLACE VIEW CARAVELO_DB.RAW.AMADEUS_FLAT AS
SELECT
  SPLIT_PART(value:c1::string, ',', 1) AS Record_Locator,
  TO_TIMESTAMP_NTZ(SPLIT_PART(value:c1::string, ',', 2)) AS Creation_Date,
  SPLIT_PART(value:c1::string, ',', 3) AS Pax_Type,
  SPLIT_PART(value:c1::string, ',', 4) AS Pax_Name,
  SPLIT_PART(value:c1::string, ',', 5) AS Dep_Stn,
  SPLIT_PART(value:c1::string, ',', 6) AS Arr_Stn,
  SPLIT_PART(value:c1::string, ',', 7) AS Flight_Num,
  TO_DATE(SPLIT_PART(value:c1::string, ',', 8)) AS Dep_Date,
  SPLIT_PART(value:c1::string, ',', 9) AS Booking_Sts,
  SPLIT_PART(value:c1::string, ',', 10) AS Fare_Basis,
  SPLIT_PART(value:c1::string, ',', 11) AS Tkt_Number
FROM CARAVELO_DB.RAW.AMADEUS_RAW;

SELECT * FROM CARAVELO_DB.RAW.AMADEUS_FLAT;
-- RECORD_LOCATOR	CREATION_DATE	PAX_TYPE	PAX_NAME	DEP_STN	ARR_STN	FLIGHT_NUM	DEP_DATE	BOOKING_STS	FARE_BASIS	TKT_NUMBER
-- SAFPFF	2025-01-30 22:15:00.000	A	URB MILLANIONSHIRS MR	JED	DOH	QR1189	2025-01-30	HK	VJR3R1SQ	1572121634985
-- WADTAS	2024-06-10 09:00:00.000	A	URB MILLANIONSHIPS MR	YYC	MSP	WS6340	2024-06-19	OK	KO7D02EK	8382187552509
-- 1AEPTX	2024-07-01 11:30:00.000	A	MSR SUZANNE LEE	MAD	CDG	IB1234	2024-07-15	HL	ECO123	9988776655443

-----------------------------------------------------------------------------

CREATE OR REPLACE VIEW CARAVELO_DB.RAW.SABRE_FLAT AS
SELECT
  SPLIT_PART(value:c1::string, ',', 1)  AS PNR,
  TO_TIMESTAMP_NTZ(SPLIT_PART(value:c1::string, ',', 2)) AS Create_Date_UTC,
  SPLIT_PART(value:c1::string, ',', 3)  AS Passenger_Name,
  SPLIT_PART(value:c1::string, ',', 4)  AS Frequent_Flyer_Number,
  SPLIT_PART(value:c1::string, ',', 5)  AS Origin,
  SPLIT_PART(value:c1::string, ',', 6)  AS Destination,
  SPLIT_PART(value:c1::string, ',', 7)  AS Flight_Number,
  TO_DATE(SPLIT_PART(value:c1::string, ',', 8)) AS DepartureDate,
  SPLIT_PART(value:c1::string, ',', 9)  AS Status,
  SPLIT_PART(value:c1::string, ',', 10) AS Class,
  SPLIT_PART(value:c1::string, ',', 11) AS TicketNumber
FROM CARAVELO_DB.RAW.SABRE_RAW;

SELECT * FROM CARAVELO_DB.RAW.SABRE_FLAT;
-- PNR	CREATE_DATE_UTC	PASSENGER_NAME	FREQUENT_FLYER_NUMBER	ORIGIN	DESTINATION	FLIGHT_NUMBER	DEPARTUREDATE	STATUS	CLASS	TICKETNUMBER
-- ABC123	2026-01-27 18:30:00.000	MADRID OCTUBRE	LY123456	MAD	SCL	LA705	2026-01-27	OK	ECONOMY	0452161785032
-- DEF456	2024-12-20 14:22:01.000	JOHN SMITH	BA789012	LHR	JFK	BA178	2024-12-24	HK	PREMIUM_ECONOMY	
-- DEF456	2024-12-20 14:22:01.000	JANE SMITH	BA789013	LHR	JFK	BA178	2024-12-24	HK	PREMIUM_ECONOMY	
-- GHI789	2024-10-05 08:15:47.000	ALICE DOE		CDG	MIA	AF123	2024-10-20	XX	ECONOMY	1122334455667

-----------------------------------------------------------------------------

CREATE OR REPLACE VIEW CARAVELO_DB.RAW.VUELING_FLAT AS
SELECT
  b.value:booking_reference::string AS Booking_Reference,
  b.value:created_at::timestamp_ntz AS Creation_Date,
  p.value:name::string AS Pax_Name,
  p.value:type::string AS Pax_Type,
  f.value:origin::string AS Dep_Stn,
  f.value:destination::string AS Arr_Stn,
  f.value:flight_number::string AS Flight_Num,
  f.value:departure_date::date AS Dep_Date,
  b.value:price.currency::string AS Currency,
  b.value:price.total::float AS Price_Total
FROM CARAVELO_DB.RAW.VUELING_RAW,
     LATERAL FLATTEN(input => value) b,
     LATERAL FLATTEN(input => b.value:passengers) p,
     LATERAL FLATTEN(input => b.value:flights) f;

SELECT * FROM CARAVELO_DB.RAW.VUELING_FLAT;
-- BOOKING_REFERENCE	CREATION_DATE	PAX_NAME	PAX_TYPE	DEP_STN	ARR_STN	FLIGHT_NUM	DEP_DATE	CURRENCY	PRICE_TOTAL
-- ZJ2M8J	2025-02-23 10:15:00.000	Indiana Jones	adult	BCN	SVQ	VY2225	2025-06-21	EUR	1433.88
-- ZJ2M8J	2025-02-23 10:15:00.000	Indiana Jones	adult	SVQ	BCN	VY2215	2025-06-25	EUR	1433.88
-- ZJ2M8J	2025-02-23 10:15:00.000	Lindi Jones	child	BCN	SVQ	VY2225	2025-06-21	EUR	1433.88
-- ZJ2M8J	2025-02-23 10:15:00.000	Lindi Jones	child	SVQ	BCN	VY2215	2025-06-25	EUR	1433.88
-- 9H7J2K	2024-11-11 09:30:00.000	Angel Cancelo Márquez	adult	SCQ	BCN	FR6333	2016-04-15	EUR	49.99
-- L1M3N5	2024-08-01 16:45:00.000	Tech Demo User	adult	FRA	LIS	VY7890	2024-09-10	EUR	129.5

-- ==============================================================================================
-- (OPTIONAL) BUILDING FLATTENED VIEW IN RAW FROM EXTERNAL TABLES VIA DBT EXTERNAL TABLES PACKAGE ()
-- ==============================================================================================

-- The command was run in dbt: dbt run-operation stage_external_sources

SELECT * FROM CARAVELO_DB.RAW.AMADEUS_RAW_DBT LIMIT 5;
SELECT * FROM CARAVELO_DB.RAW.SABRE_RAW_DBT LIMIT 5;
SELECT * FROM CARAVELO_DB.RAW.VUELING_RAW_DBT LIMIT 5;



