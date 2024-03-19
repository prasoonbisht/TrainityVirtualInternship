use ig_clone;

-- MARKETING ANALYSIS
-- 1) 5 oldest users of the Instagram from the database provided
SELECT 
    *
FROM
    users
ORDER BY created_at ASC
LIMIT 5;

-- 2) Users who have never posted a single photo on Instagram
SELECT 
    u.id, u.username
FROM
    users AS u
        LEFT JOIN
    photos AS p ON u.id = p.user_id
WHERE
    user_id IS NULL;
    
    
/* 3) The team has organized a contest where the user with the most likes on a single photo wins.
 The winner of the contest and their details to the team */
SELECT 
    u.id AS user_id,
    u.username,
    p.image_url,
    COUNT(l.user_id) AS likes
FROM
    users u
        LEFT JOIN
    photos p ON p.user_id = u.id
        LEFT JOIN
    likes l ON p.id = l.photo_id
GROUP BY user_id , u.username , p.image_url
ORDER BY likes DESC
LIMIT 1;

-- 4) The top five most commonly used hashtags on the platform
SELECT 
    tag_id, tag_name, COUNT(tag_name) AS hastag_count
FROM
    photo_tags pt
        LEFT JOIN
    tags t ON pt.tag_id = t.id
GROUP BY tag_id
ORDER BY hastag_count DESC
LIMIT 5;

-- 5)  The day of the week when most users register on Instagram
SELECT 
    DAYNAME(created_at) AS day_name,
    COUNT(*) AS registration_count
FROM
    users
GROUP BY day_name
ORDER BY registration_count DESC;


-- INVESTOR METRICS
/* 1) 
The average number of posts per user on Instagram */
SELECT 
    user_id,
    COUNT(id) / COUNT(DISTINCT user_id) AS avg_posts_per_user
FROM
    photos
GROUP BY user_id;

/* 1) 
 The total number of photos on Instagram divided by the total number of users */
SELECT 
    COUNT(image_url) / COUNT(DISTINCT user_id) AS avg_posts_per_user
FROM
    photos; 
 
 
-- 2)  Users (potential bots) who have liked every single photo on the site, as this is not typically possible for a normal user
SELECT 
    user_id, COUNT(photo_id) AS liked_photos
FROM
    likes
GROUP BY user_id
HAVING liked_photos = (SELECT 
        COUNT(DISTINCT (photo_id))
    FROM
        likes)