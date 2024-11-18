-- 1. Are there any tables with duplicate or missing null values? If so, how would you handle them? 
-- 1.
SELECT id , COUNT(*)
FROM users
GROUP BY id 
HAVING COUNT(*) > 1;

SELECT *
FROM users
WHERE id IS NULL OR username IS NULL OR created_at IS NULL;

-- 2.
SELECT id, COUNT(*)
FROM photos
GROUP BY id
HAVING COUNT(*) > 1;

SELECT *
FROM photos
WHERE user_id IS NULL OR image_url IS NULL;

-- 3.
SELECT id, COUNT(*)
FROM comments
GROUP BY id
HAVING COUNT(*) > 1;

SELECT *
FROM comments
WHERE id IS NULL OR user_id IS NULL OR photo_id IS NULL;

-- 4.
SELECT user_id, photo_id, COUNT(*)
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

SELECT *
FROM likes
WHERE user_id IS NULL OR photo_id IS NULL;

-- 5.
SELECT follower_id,followee_id, COUNT(*)
FROM follows
GROUP BY follower_id,followee_id
HAVING COUNT(*) > 1;

SELECT *
FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL;

-- 6.
SELECT id , COUNT(*) AS duplicate_count
FROM tags
GROUP BY id 
HAVING COUNT(*) > 1;

SELECT *
FROM tags
WHERE id IS NULL OR created_at IS NULL OR tag_name IS NULL;


-- 7.
SELECT photo_id,tag_id, COUNT(*)
FROM photo_tags
GROUP BY photo_id,tag_id
HAVING COUNT(*) > 1;

SELECT *
FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;

-- There is no null and no duplicates 

-- 2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base? 

-- User table is connected to others tables like photos, comments, likes

-- photos
select u.id, u.username, count(p.user_id) as count_photo_id
from users u left join photos p
on u.id = p.user_id
group by u.id, u.username;

-- comments
select u.id, u.username, count(c.user_id) as count_comment_id
from users u left join comments c
on u.id = c.user_id
group by u.id, u.username;

-- likes
select u.id, u.username, count(l.user_id) as count_like_id
from users u left join likes l
on u.id = l.user_id
group by u.id, u.username; 

-- final query

select u.id, u.username, COALESCE(p.count_photo_id, 0) AS count_photo_id, COALESCE(c.count_comment_id, 0) AS count_comment_id, COALESCE(l.count_like_id, 0) AS count_like_id
from users u 
left join (select user_id, count(*) as count_photo_id from photos group by user_id) p
ON u.id = p.user_id
left join (select user_id, count(*) as count_comment_id from comments group by user_id) c
ON u.id = c.user_id
left join (select user_id, count(*) as count_like_id from likes group by user_id) l
ON u.id = l.user_id
group by  u.id, u.username;

-- 3. Calculate the average number of tags per post (photo_tags and photos tables). 

SELECT AVG(tag_count) AS average_tags
FROM (
SELECT p.id , COUNT(t.tag_id) AS tag_count
FROM photos p
LEFT JOIN photo_tags t ON p.id = t.photo_id
GROUP BY p.id
) AS photo_tag_counts;

-- 4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

select u.id as Users, MAX(c.comment_count) as Max_comment, Max(l.like_count) as Max_likes
from users u
left join 
(select user_id, count(id) as comment_count from comments group by user_id) c
ON u.id = c.user_id
left join
(select user_id, count(photo_id) as like_count from likes group by user_id) l
ON u.id = l.user_id 
group by Users
order by Max_comment desc, Max_likes desc Limit 2;

-- 5. Which users have the highest number of followers and followings? 

SELECT 
    u.id AS user_id,
    u.username AS username,
    COUNT(f.followee_id) AS followings_count,
    COUNT(fw.follower_id) AS followers_count
FROM 
    users u
LEFT JOIN 
    follows f ON u.id = f.followee_id
LEFT JOIN
    follows fw ON u.id = fw.follower_id
GROUP BY 
    u.id, u.username
ORDER BY 
    followings_count DESC
LIMIT 1;

-- 6. Calculate the average engagement rate (likes, comments) per post for each user. 
select u.id, u.username , AVG(l.photo_id) as avg_likes, AVG(c.id) as avg_comments
from users u
left join likes l
ON u.id = l.user_id
left join comments c
ON u.id = c.user_id
group by u.id;

-- 7.Get the list of users who have never liked any post (users and likes tables) 

select id as user_id, username from users
where id NOT IN (select user_id from likes);

-- 8. How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?
-- 9. Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies? 

-- 10.Calculate the total number of likes, comments, and photo tags for each user. 

select u.id as User_id, u.username as username, count(distinct l.photo_id) as like_count,
count(distinct c.id) as comment_count, count(distinct pt.tag_id) as tag_count
from users u
left join photos p
ON u.id = p.user_id
left join likes l
ON u.id = l.user_id
left join comments c
ON u.id = c.user_id
left join photo_tags pt
ON p.user_id = pt.photo_id
group by User_id;

-- 11. Rank users based on their total engagement (likes, comments, shares) over a month. 
With Engagment AS
(select u.id as User_Id, u.username as Username,
c.comment_count as comment_count, l.like_count as like_count ,
(c.comment_count + l.like_count) as engagment_count
from users u
left join
(select user_id, COUNT(id) as comment_count from comments 
where created_at between '2024-10-1' and '2024-10-30'
group by user_id) c
ON u.id = c.user_id
left join
(select user_id, COUNT(photo_id) as like_count from likes 
where created_at between '2024-10-1' and '2024-10-30'
group by user_id)l
ON u.id = l.user_id )
select User_id, username, comment_count,like_count, engagment_count,
Dense_rank() over (order by  engagment_count desc) as Engangment_rank
from Engagment
order by Engangment_rank;

-- 12.Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first. 

WITH HashtagLikes AS (
    SELECT ht.tag_name, COUNT(l.photo_id) AS total_likes, COUNT(DISTINCT p.id) AS total_posts
    FROM tags ht
    JOIN photo_tags pt ON ht.id = pt.tag_id
    JOIN photos p ON pt.photo_id = p.id
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY ht.tag_name
),
AverageLikesPerHashtag AS (
    SELECT tag_name, ROUND((CAST(total_likes AS FLOAT) / total_posts),2) AS avg_likes
    FROM HashtagLikes
)
SELECT tag_name, avg_likes
FROM AverageLikesPerHashtag
group by tag_name
having avg_likes >= 34.5
ORDER BY avg_likes DESC;

-- 13.Retrieve the users who have started following someone after being followed by that person 

SELECT 
    f1.follower_id AS user_id,
    u.username
FROM 
    follows f1
JOIN 
    follows f2 ON f1.follower_id = f2.followee_id
JOIN 
    users u ON f1.follower_id = u.id
WHERE 
    f1.created_at > f2.created_at
GROUP BY 
    f1.follower_id, u.username;