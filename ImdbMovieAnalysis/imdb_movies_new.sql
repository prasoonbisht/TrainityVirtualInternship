# Imdb Movie Analysis (New)

use imdb;

# 1. Movie Genre Analysis: Analyze the distribution of movie genres and their impact on the IMDB score.
SELECT 
    individual_genre,
    ROUND(AVG(imdb_score), 2) AS average_imdb_score,
    ROUND(STDDEV(imdb_score), 2) AS standard_deviation_imdb_score,
    COUNT(*) AS genre_count,
    ROUND(COUNT(*) * 100.0 / (SELECT 
                    COUNT(*)
                FROM
                    imdb_clean),
            2) AS genre_percentage,
    CONCAT(ROUND(MAX(imdb_score), 1),
            ' / ',
            ROUND(MIN(imdb_score), 1)) AS max_min_imdb_score
FROM
    (SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(genres, '|', n), '|', - 1) AS individual_genre,
            imdb_score
    FROM
        imdb_clean
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS numbers ON CHAR_LENGTH(genres) - CHAR_LENGTH(REPLACE(genres, '|', '')) > n - 1) AS genres
GROUP BY 1
ORDER BY genre_percentage DESC;

# 2.  Movie Duration Analysis: Analyze the distribution of movie durations and its impact on the IMDB score.
SELECT
    duration_class,
    ROUND(AVG(imdb_score), 1) AS average_imdb_score,
    (
        SELECT 
            ROUND(AVG(imdb_score), 1)
        FROM (
            SELECT 
                imdb_score,
                ROW_NUMBER() OVER (ORDER BY imdb_score) AS row_num,
                COUNT(*) OVER () AS total_rows
            FROM
                imdb_clean
            WHERE
                CASE
                    WHEN duration BETWEEN 0 AND 90 THEN 'Short (0-90 mins)'
					WHEN duration BETWEEN 91 AND 120 THEN 'Medium (91-120 mins)'
					WHEN duration > 120 THEN 'Long (>120 mins)'
				ELSE 'Unknown'
                END = duration_class
        ) AS median_query
        WHERE
            row_num BETWEEN total_rows / 2 AND total_rows / 2 + 1
    ) AS median_imdb_score,
    COUNT(*) AS num_movies
FROM (
    SELECT
        CASE
            WHEN duration BETWEEN 0 AND 90 THEN 'Short (0-90 mins)'
            WHEN duration BETWEEN 91 AND 120 THEN 'Medium (91-120 mins)'
            WHEN duration > 120 THEN 'Long (>120 mins)'
            ELSE 'Unknown'
        END AS duration_class,
        imdb_score
    FROM
        imdb_clean
) AS classified_data
GROUP BY
    duration_class
ORDER BY
    duration_class;
    
# 3. Language Analysis: Situation: Examine the distribution of movies based on their language.
SELECT 
    language,
    COUNT(*) AS total_movies,
    ROUND(AVG(imdb_score), 1) AS average_imdb_score,
    (
        SELECT ROUND(AVG(imdb_score), 1)
        FROM (
            SELECT 
                imdb_score,
                ROW_NUMBER() OVER (ORDER BY imdb_score) AS row_num,
                COUNT(*) OVER () AS total_rows
            FROM 
                imdb_clean
        ) AS median_query
        WHERE 
            row_num BETWEEN total_rows / 2 AND total_rows / 2 + 1
    ) AS median_imdb_score,
    ROUND(STDDEV(imdb_score), 1) AS standard_deviation_imdb_score
FROM 
    imdb_clean
GROUP BY 
    language;
    

# 4. Director Analysis: Influence of directors on movie ratings.
SELECT 
	director_name, 
    ROUND(((gross - budget)/10000000), 2) AS profit_in_crore,
    ROUND(AVG(imdb_score), 1) AS average_imdb_score, 
    ROUND(PERCENT_RANK() OVER (ORDER BY AVG(imdb_score) ASC), 4) AS percentile_rank
FROM 
	imdb_clean 
GROUP BY 1, 2 
ORDER BY profit_in_crore DESC 
LIMIT 10;


# 5. Budget Analysis: Explore the relationship between movie budgets and their financial success.
SELECT
    ROUND((SUM((budget - avg_budget) * (gross - avg_gross)) / COUNT(*)) / (STDDEV(budget) * STDDEV(gross)), 3) AS correlation_coefficient
FROM (
    SELECT
        budget,
        gross,
        (SELECT AVG(budget) FROM imdb_clean) AS avg_budget,
        (SELECT AVG(gross) FROM imdb_clean) AS avg_gross
    FROM
        imdb_clean
) AS d;

SELECT 
	movie_title,
    ROUND(((gross - budget)/10000000), 2) AS profit_in_crore
FROM 
	imdb_clean
ORDER BY 2 DESC
LIMIT 10;
