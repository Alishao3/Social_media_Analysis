-- 1. Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users? 

WITH TotalLikes AS (
    SELECT u.id, COUNT(distinct l.photo_id) AS total_likes
    FROM users u
    LEFT JOIN likes l ON u.id = l.user_id
    GROUP BY u.id
),
TotalComments AS (
    SELECT u.id, COUNT(distinct c.photo_id) AS total_comments
    FROM users u
    LEFT JOIN comments c ON u.id = c.user_id
    GROUP BY u.id
),
PhotosPosted AS (
    SELECT user_id, COUNT(id) AS total_photos_posted
    FROM photos
    GROUP BY user_id
),
Followers AS (
    SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers
    FROM follows
    GROUP BY followee_id
),
UniqueTags AS (
    SELECT p.user_id, COUNT(DISTINCT pt.tag_id) AS unique_tags_used
    FROM photos p
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.user_id
)
SELECT u.id AS user_id, u.username,
    COALESCE(tl.total_likes, 0) AS total_likes,
    COALESCE(tc.total_comments, 0) AS total_comments,
    COALESCE(pp.total_photos_posted, 0) AS total_photos_posted,
    COALESCE(f.total_followers, 0) AS total_followers,
    COALESCE(ut.unique_tags_used, 0) AS unique_tags_used,
    (COALESCE(tl.total_likes, 0) + COALESCE(tc.total_comments, 0)) AS total_engagement
FROM users u
LEFT JOIN TotalLikes tl ON u.id = tl.id
LEFT JOIN TotalComments tc ON u.id = tc.id
LEFT JOIN PhotosPosted pp ON u.id = pp.user_id
LEFT JOIN Followers f ON u.id = f.user_id
LEFT JOIN UniqueTags ut ON u.id = ut.user_id
GROUP BY u.id 
having total_photos_posted >0
ORDER BY total_engagement DESC, total_followers DESC, total_photos_posted DESC
LIMIT 10;

-- 3.Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns? 

SELECT t.tag_name, 
       COUNT(DISTINCT p.id) AS photo_count,
       COUNT(DISTINCT l.user_id) AS likes_count,
       COUNT(DISTINCT c.id) AS comments_count,
       (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS engagement_score
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
JOIN photos p ON pt.photo_id = p.id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY t.tag_name
ORDER BY engagement_score DESC
LIMIT 10;

-- 4. Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns? 
SELECT 
    HOUR(p.created_dat) AS post_hour,
    DAYOFWEEK(p.created_dat) AS post_day,
    COUNT(DISTINCT p.id) AS total_photos_posted,
    COUNT(DISTINCT l.photo_id) AS total_likes_received,
    COUNT(DISTINCT c.id) AS total_comments_made
FROM photos p
JOIN likes l ON p.id = l.photo_id
JOIN comments c ON p.id = c.photo_id
GROUP BY post_hour, post_day;

-- 5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers? 
SELECT 
    u.id AS user_id, 
    u.username,
    COALESCE(tl.total_likes, 0) AS Total_Likes,
    COALESCE(tc.total_comments, 0) AS Total_Comments,
    COALESCE(pp.total_photos_posted, 0) AS Total_Posts,
    COALESCE(f.total_followers, 0) AS Total_Followers,
    ROUND((COALESCE(tl.total_likes, 0) + COALESCE(tc.total_comments, 0)) / (COALESCE(pp.total_photos_posted, 0)),2) AS Engagement_Rate
FROM users u
LEFT JOIN (
    SELECT u.id, COUNT(DISTINCT l.photo_id) AS total_likes
    FROM users u
    LEFT JOIN likes l ON u.id = l.user_id
    GROUP BY u.id
) tl ON u.id = tl.id
LEFT JOIN (
    SELECT u.id, COUNT(DISTINCT c.photo_id) AS total_comments
    FROM users u
    LEFT JOIN comments c ON u.id = c.user_id
    GROUP BY u.id
) tc ON u.id = tc.id
LEFT JOIN (
    SELECT user_id, COUNT(id) AS total_photos_posted
    FROM photos
    GROUP BY user_id
) pp ON u.id = pp.user_id
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers
    FROM follows
    GROUP BY followee_id
) f ON u.id = f.user_id
GROUP BY u.id 
HAVING Total_Posts > 0
ORDER BY  Engagement_Rate DESC, Total_Followers DESC, Total_Posts DESC 
LIMIT 10;


-- 6.Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations? 
-- 1)For User Type(OLD/NEW USER)
SELECT 
    id AS user_id,
    username,
    created_at AS signup_date,
    CASE 
        WHEN DATEDIFF('2017-05-04', created_at) <= 60 THEN 'New User'
        ELSE 'Old User'
    END AS user_type
FROM 
    users;
    
-- 2) for user_category(HIGHLY/MODERATE/LESS ACTIVE)
SELECT 
    u.id AS user_id,
    u.username,
    p.total_post,
    COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) AS total_engagement,
    CASE
        WHEN COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) > 150 THEN 'Highly Active'
        WHEN COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) BETWEEN 50 AND 150 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS user_category
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_likes
    FROM ig_clone.likes
    GROUP BY user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
) c ON u.id = c.user_id
LEFT JOIN (
	SELECT user_id, count(id) AS total_post
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
group by u.id
having p.total_post >0
ORDER BY user_id DESC;

-- 7. If data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns? 

-- 8.How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events? 

-- 9.How would you approach this problem, if the objective and subjective questions weren't given? 

-- 10.Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?
 -- i) First I have created table named User_Interactions
CREATE TABLE User_Interactions(
	id INT AUTO_INCREMENT UNIQUE PRIMARY KEY,
	username VARCHAR(255) NOT NULL,
	Engagement_Type varchar(255) not null
);

-- ii) Inserted value in table by referring table 'users' for column name 'username'
INSERT INTO User_Interactions (username,Engagement_Type ) VALUES 
('Kenton_Kirlin', 'Likes'),
 ('Andre_Purdy85', 'Comments'), 
 ('Harley_Lind18', 'Likes'),
 ('Arely_Bogan63', 'Comments'), 
 ('Aniya_Hackett', 'Likes'), 
 ('Travon.Waters', 'Likes'), 
 ('Kasandra_Homenick', 'Comments'), 
 ('Tabitha_Schamberger11', 'Likes'),
 ('Gus93', 'Likes'), 
 ('Presley_McClure', 'Comments'), 
 ('Justina.Gaylord27', 'Likes'), 
 ('Dereck65', 'Likes'), 
 ('Alexandro35', 'Comments'), 
 ('Jaclyn81', 'Likes'), 
 ('Billy52', 'Likes'), 
 ('Annalise.McKenzie16', 'Comments'), 
 ('Norbert_Carroll35', 'Likes'), 
 ('Odessa2', 'Comments'), 
 ('Hailee26', 'Likes'), 
 ('Delpha.Kihn', 'Likes'), 
 ('Rocio33', 'Comments'), 
 ('Kenneth64', 'Comments'), 
 ('Eveline95', 'Likes'),
 ('Maxwell.Halvorson', 'Likes'), 
 ('Tierra.Trantow', 'Comments'),
 ('Josianne.Friesen', 'Likes'), 
 ('Darwin29', 'Likes'),
 ('Jaime53', 'Comments'),
 ('Kaley9', 'Comments'), 
 ('Aiyana_Hoeger', 'Like'), 
 ('Irwin.Larson', 'Comments'), 
 ('Yvette.Gottlieb91', 'Likes'), 
 ('Pearl7', 'Comments'), 
 ('Lennie_Hartmann40', 'Comments'), 
 ('Ollie_Ledner37', 'Comments'), 
 ('Yazmin_Mills95', 'Comments'), 
 ('Jordyn.Jacobson2', 'Comments'), 
 ('Kelsi26', 'Likes'), 
 ('Rafael.Hickle2', 'Likes'), 
 ('Mckenna17', 'Comments'), 
 ('Maya.Farrell', 'Likes'), 
 ('Janet.Armstrong', 'Comments'), 
 ('Seth46', 'Likes'), 
 ('David.Osinski47', 'Comments'), 
 ('Malinda_Streich', 'Comments'), 
 ('Harrison.Beatty50', 'Likes'), 
 ('Granville_Kutch', 'Likes'), 
 ('Morgan.Kassulke', 'Comments'), 
 ('Gerard79', 'Comments'), 
 ('Mariano_Koch3', 'Likes'), 
 ('Zack_Kemmer93', 'Likes'), 
 ('Linnea59', 'Comments'), 
 ('Duane60', 'Comments'), 
 ('Meggie_Doyle', 'Likes'), 
 ('Peter.Stehr0', 'Likes'), 
 ('Julien_Schmidt', 'Comments'), 
 ('Aurelie71', 'Likes'), 
 ('Cesar93', 'Comments'), 
 ('Sam52', 'Likes'), 
 ('Jayson65', 'Comments'), 
 ('Ressie_Stanton46', 'Comments'), 
 ('Elenor88', 'Likes'), 
 ('Florence99', 'Comments'), 
 ('Adelle96', 'Likes'), 
 ('Mike.Auer39', 'Comments'), 
 ('Emilio_Bernier52', 'Comments'), 
 ('Franco_Keebler64', 'Likes'), 
 ('Karley_Bosco', 'Comments'), 
 ('Erick5', 'Likes'), 
 ('Nia_Haag', 'Comments'), 
 ('Kathryn80', 'Likes'), 
 ('Jaylan.Lakin', 'Likes'), 
 ('Hulda.Macejkovic', 'Comments'), 
 ('Leslie67', 'Likes'), 
 ('Janelle.Nikolaus81', 'Likes'), 
 ('Donald.Fritsch', 'Comments'), 
 ('Colten.Harris76', 'Comments'), 
 ('Katarina.Dibbert', 'Likes'), 
 ('Darby_Herzog', 'Likes'), 
 ('Esther.Zulauf61', 'Likes'), 
 ('Aracely.Johnston98', 'Comments'), 
 ('Bartholome.Bernhard', 'Comments'), 
 ('Alysa22', 'Likes'), 
 ('Milford_Gleichner42', 'Likes'), 
 ('Delfina_VonRueden68', 'Comments'), 
 ('Rick29', 'Likes'), 
 ('Clint27', 'Likes'), 
 ('Jessyca_West', 'Comments'), 
 ('Esmeralda.Mraz57', 'Likes'), 
 ('Bethany20', 'Comments'), 
 ('Frederik_Rice', 'Likes'), 
 ('Willie_Leuschke', 'Likes'),
 ('John_schke', 'Likes'), 
 ('Damon35', 'Comments'), 
 ('Nicole71', 'Comments'), 
 ('Keenan.Schamberger60', 'Likes'), 
 ('Tomas.Beatty93', 'Likes'), 
 ('Imani_Nicolas17', 'Likes'), 
 ('Alek_Watsica', 'Comments'), 
 ('Javonte83', 'Likes');

-- iii) update the "Engagement_Type" column to change all instances of "Like" to "Heart"
-- Disable safe updates temporarily
SET SQL_SAFE_UPDATES = 0;

-- Perform the update operation
UPDATE User_Interactions  
SET Engagement_Type = 'Heart'  
WHERE Engagement_Type = 'Likes'  
AND id IS NOT NULL;

-- Re-enable safe updates after the operation
SET SQL_SAFE_UPDATES = 1;