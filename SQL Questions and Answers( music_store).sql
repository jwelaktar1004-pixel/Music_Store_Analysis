-- Business Questions & Answers


--  Q1: Who is the senior most employee based on job title?

CREATE VIEW senior_most_employee AS
SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1;

--  Q2: Which countries have the most Invoices?

CREATE VIEW invoice_count_by_country AS
SELECT COUNT(*) AS c, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

-- Q3: What are top 3 values of total invoice?

CREATE VIEW top_3_invoice_totals AS
SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;

 -- Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals

CREATE VIEW best_customer_city AS
SELECT billing_city, SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;

-- Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money.

CREATE VIEW best_customer AS
SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, first_name, last_name
ORDER BY total_spending DESC
LIMIT 1;

-- 2nd phase questions:

Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A.

-- Method 1:

CREATE VIEW rock_music_listeners_method1 AS
SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE invoice_line.track_id IN (
    SELECT track_id 
    FROM track
    JOIN genre ON track.genre_id = genre.genre_id
    WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

-- Method 2:

CREATE VIEW rock_listeners_method2 AS
SELECT DISTINCT 
    customer.email, 
    customer.first_name, 
    customer.last_name, 
    genre.name AS genre_name
FROM customer
JOIN invoice 
    ON invoice.customer_id = customer.customer_id
JOIN invoice_line 
    ON invoice_line.invoice_id = invoice.invoice_id
JOIN track 
    ON track.track_id = invoice_line.track_id
JOIN genre 
    ON genre.genre_id = track.genre_id
WHERE genre.name = 'Rock'
ORDER BY customer.email;


-- Q2: Let's invite the artists who have written the most rock music in our dataset. 
-- -- Write a query that returns the Artist name and total track count of the top 10 rock bands.

CREATE VIEW top_rock_artists AS
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC
LIMIT 10;

 -- Q3: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

CREATE VIEW tracks_longer_than_average AS
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds)
    FROM track
)
ORDER BY milliseconds DESC;


-- 3rd Phase Questions

Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

-- Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
-- which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
-- Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
-- so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
-- for each artist. 

CREATE VIEW customer_spending_on_top_artist AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    a.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN artist a ON a.artist_id = alb.artist_id
WHERE a.artist_id = (
        SELECT artist.artist_id
        FROM invoice_line
        JOIN track ON track.track_id = invoice_line.track_id
        JOIN album ON album.album_id = track.album_id
        JOIN artist ON artist.artist_id = album.artist_id
        GROUP BY artist.artist_id, artist.name
        ORDER BY SUM(invoice_line.unit_price * invoice_line.quantity) DESC
        LIMIT 1
)
GROUP BY c.customer_id, c.first_name, c.last_name, a.name
ORDER BY amount_spent DESC;


--  Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
-- with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
-- the maximum number of purchases is shared return all Genres. 

--  Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

--  Method 1: 

CREATE VIEW top_genre_by_country AS
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, 
		   genre.name, genre.genre_id,
		   ROW_NUMBER() OVER(PARTITION BY customer.country 
							 ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
)
SELECT * FROM popular_genre WHERE RowNo = 1;
select * from top_genre_by_country

-- Method 2:

CREATE VIEW top_genre_by_country_recursive AS
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
	),
	max_genre_per_country AS (
		SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
	)
SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country 
ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;
select * from top_genre_by_country_recursive


-- Q3: Write a query that determines the customer that has spent the most on music for each country. 
-- -- Write a query that returns the country along with the top customer and how much they spent. 
-- -- For countries where the top amount spent is shared, provide all customers who spent this amount. 

-- Steps to Solve:  Similar to the above question. There are two parts in question- 
-- first find the most spent on music for each country and second filter the data for respective customers. 

-- Method 1:

CREATE VIEW top_customer_by_country AS
WITH customer_with_country AS (
	SELECT customer.customer_id, first_name, last_name, billing_country,
		   SUM(total) AS total_spending,
		   ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
)
SELECT * FROM customer_with_country WHERE RowNo = 1;

-- Method 2:

CREATE VIEW top_customer_by_country_recursive AS
WITH 
    customer_with_country AS (
        SELECT 
            customer.customer_id,
            customer.first_name,
            customer.last_name,
            invoice.billing_country,
            SUM(invoice.total) AS total_spending
        FROM invoice
        JOIN customer 
            ON customer.customer_id = invoice.customer_id
        GROUP BY 
            customer.customer_id,
            customer.first_name,
            customer.last_name,
            invoice.billing_country
    ),
    
    country_max_spending AS (
        SELECT 
            billing_country,
            MAX(total_spending) AS max_spending
        FROM customer_with_country
        GROUP BY billing_country
    )

SELECT 
    cc.billing_country,
    cc.total_spending,
    cc.first_name,
    cc.last_name,
    cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
    ON cc.billing_country = ms.billing_country
   AND cc.total_spending = ms.max_spending
ORDER BY cc.billing_country;








