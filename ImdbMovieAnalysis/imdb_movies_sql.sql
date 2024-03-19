use imdb;
select * from imdb_clean;

/*
# Dropping the columns not to be used, if the data is not already cleaned
alter table imdb_clean
drop column color, drop column director_facebook_likes, drop column actor_3_facebook_likes, drop column actor_2_name, 
drop column actor_1_facebook_likes, drop column cast_total_facebook_likes, drop column actor_3_name,
drop column facenumber_in_poster, drop column plot_keywords, drop column movie_imdb_link, drop column country, 
drop column content_rating, drop column actor_2_facebook_likes, drop column aspect_ratio, drop column movie_facebook_likes;
*/


# Removing special charcters from movie_title column
UPDATE imdb_clean
SET movie_title = REGEXP_REPLACE(movie_title, '[^a-zA-Z0-9]', '');


-- 1. Top 10 movies with highest profit
select 
	row_number()over() as ranking, 
    movie_title, 
    (gross-budget) as profit from imdb_clean
order by profit desc
limit 10;
 
 
 -- 2. Top 250 movies by imdb score
 select 
	row_number()over(order by imdb_score desc) as ranking,
	movie_title, 
	imdb_score, 
	language 
from 
	imdb_clean 
where num_voted_users > 25000
order by imdb_score desc 
limit 250;
 
 
 -- 3. Movies not in English in the Top 250 list
 select 
	row_number()over(order by imdb_score desc) as ranking,
	movie_title, 
    imdb_score, 
    language 
from (
	select movie_title, 
		imdb_score, 
        language, 
        num_voted_users 
	from 
		imdb_clean 
	where num_voted_users > 25000
	order by imdb_score desc limit 250) as top_250
where language != 'English';
 
 
 -- 4. Top 10 Directors based on imdb score
 select 
	director_name as Top_10_Directors, 
    round(avg(imdb_score),2) as avg_score 
from 
	imdb_clean
 group by director_name 
 order by avg_score desc, director_name
 limit 10;
 
 
 -- 5. Popular genre
select 
	genre, 
    count(genre) as total_genre_count
from (
    select substring_index(substring_index(genres, '|', 1), '|', -1) as genre from imdb_clean
    union all
    select substring_index(substring_index(genres, '|', 2), '|', -1) as genre from imdb_clean
    union all
    select substring_index(substring_index(genres, '|', 3), '|', -1) as genre from imdb_clean
    union all
    select substring_index(substring_index(genres, '|', 4), '|', -1) as genre from imdb_clean
) as g
group by genre
order by total_genre_count desc
limit 10;


-- 6. Movies done by actors Meryl Streep, leonardo DiCaprio and Brad Pitt
select 
	actor_1_name, 
    count(movie_title) as movie_count, 
    round(avg(num_critic_for_reviews),2) as average_critic_reviews, 
    round(avg(num_user_for_reviews),2) as average_user_reviews 
from 
	imdb_clean 
where actor_1_name = 'Meryl Streep'
union all 
select 
	actor_1_name, 
    count(movie_title) as movie_count, 
    round(avg(num_critic_for_reviews),2) as average_critic_reviews, 
    round(avg(num_user_for_reviews),2) as average_user_reviews
from 
	imdb_clean 
where actor_1_name = 'leonardo DiCaprio'
union all
select 
	actor_1_name, 
	count(movie_title) as movie_count,
	round(avg(num_critic_for_reviews),2) as average_critic_reviews, 
	round(avg(num_user_for_reviews),2) as average_user_reviews
from 
	imdb_clean 
where actor_1_name = 'Brad Pitt';


-- 7. Number of voted users over decade
select 
	concat(convert(floor(title_year/10)*10,char),"s") as decade, 
    sum(num_voted_users) as total_votes
from 
	imdb_clean 
group by decade 
order by decade;
