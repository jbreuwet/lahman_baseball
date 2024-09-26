-- 1. What range of years for baseball games played does the provided database cover?

SELECT COUNT(DISTINCT year)
FROM homegames;

-- There are 146 years covered by the database.

--2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT namefirst
	, namelast
	, height
	, g_all
	, name
FROM people
	INNER JOIN appearances
	USING(playerid)
	INNER JOIN teams
	USING(teamid)
GROUP BY namefirst
		, namelast
		, height
		, g_all
		, name
ORDER BY height ASC
LIMIT 1;

-- Eddie Gaedel is the shortest player in the database with a height of 43 inches. He only played one game for the St. Louis Browns.

--3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT namefirst
	, namelast
	, SUM(salary::numeric::money) AS total_salary
FROM (SELECT playerid
		, salary
		, salaries.yearid
	FROM salaries 
		LEFT JOIN collegeplaying
		USING(playerid)
		LEFT JOIN schools
		USING(schoolid)
	WHERE schoolname = 'Vanderbilt University'
	GROUP BY salaries.yearid, playerid, salary) AS salaries
		LEFT JOIN people
		USING(playerid)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC
LIMIT 1;

-- David Price is the player from Vanderbilt University who earned the most in the Major Leagues with a total salary of $81.9M.

--4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT CASE WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
			WHEN pos IN ('P','C') THEN 'Battery' END AS position
	, SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position;

-- In 2016, the infield positions had a total of 58,934 putouts, the battery had a total of 41,424 putouts, and the outfield had a total of 29,560 putouts.

--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

WITH decades AS (
	SELECT CONCAT((yearid/10 *10)::text, '''s') AS decade,
	*
	FROM teams
	WHERE yearid >= 1920
)
SELECT decade,
	ROUND(SUM(hr)/(SUM(g)::numeric/2), 2) AS hr_per_game,
	ROUND(SUM(so)/(SUM(g)::numeric/2), 2) AS so_per_game
FROM decades
GROUP BY decade
ORDER BY decade;

-- There seems to be a trend of an increasing number of home runs and strike outs per games as the decades increase.
	
--6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT namefirst
	, namelast
	, ROUND(SUM(sb::numeric) / (SUM(sb::numeric) + SUM(cs::numeric)) * 100, 2) AS stealing_success
FROM people
	INNER JOIN batting
	USING(playerid)
WHERE yearid = 2016
	AND (sb > 0
	OR cs > 0)
GROUP BY namefirst, namelast
HAVING (SUM(sb) + SUM(cs)) >= 20
ORDER BY stealing_success DESC;

-- In 2016, Chris Owings had the best succes stealing bases with a 91.3% success rate.

--7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT name,
	MAX(w) AS min_wins
FROM teams
WHERE wswin = 'N' AND yearid BETWEEN 1970 AND 2016
GROUP BY name
ORDER BY min_wins DESC;

-- The largest number of wins between 1970 and 2016 for a team that did not win the world series is 116 wins for the Seattle Mariners.

SELECT name,
	MIN(w) AS min_wins
FROM teams
WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016
GROUP BY name
ORDER BY min_wins;

-- The least amount of wins between 1970 and 2016 for a team that did win the world series is 63 with the Los Angeles Dodgers. This number seems to be too low for a world series win so we will investigate further.

SELECT yearid,
	SUM(w + l) AS total_games
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
ORDER BY total_games;

-- Here we find that in 1981 there was a strike and the full season was not played.

SELECT name,
	MIN(w) AS min_wins
FROM teams
WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016 AND yearid <> 1981
GROUP BY name
ORDER BY min_wins;

-- Removing the 1981 strike season we find that the least amount of wins between 1970 and 2016 for a team that did win the world series is 83 for the St. Louis Cardinals.

WITH max_wins AS (
	SELECT yearid,
		MAX(w) AS max_wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016 AND yearid <> 1981
	GROUP BY yearid
)
SELECT SUM(CASE WHEN wswin = 'Y' THEN 1 END) AS total_ws_wins,
	CONCAT(ROUND(AVG(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END) * 100, 2)::text, '%') AS win_pct
FROM max_wins
	INNER JOIN teams
	USING(yearid)
WHERE w = max_wins;

-- The team with the highest amount of wins during a given season only won the world series 23.08% of the time. 

--8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

(SELECT name,
	teams.park,
	homegames.attendance/games AS avg_attendance
FROM teams
	INNER JOIN homegames
	ON team = teamid
	AND year = yearid
WHERE yearid = 2016
	AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(SELECT name,
	teams.park,
	homegames.attendance/games AS avg_attendance
FROM teams
	INNER JOIN homegames
	ON team = teamid
	AND year = yearid
WHERE yearid = 2016
	AND games >= 10
ORDER BY avg_attendance
LIMIT 5)
ORDER BY avg_attendance DESC;

-- The 5 teams and parks with the highest average attendance in 2016 are the Los Angeles Dodgers at Dodger Stadium, the St. Louis Cardinals at Busch Stadium III, the Toronto Blue Jays at Rogers Centre, the San Francisco Giants at AT&T Park, and the Chicago Cubs at Wrigley Field.

--The 5 teams and parks with the lowest average attendance in 2016 are the Miami Marlins at Marlins Park, the Cleveland Indians at Progressive Field, the Oakland Athletics at O.co Coliseum, and the Tampa Bay Rays at Tropicana Field.


--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT people.namefirst
	, people.namelast
	, winners.yearid
	, team_name.name
FROM (SELECT playerid
		, yearid
	FROM awardsmanagers
	WHERE playerid IN
		(SELECT playerid
		FROM awardsmanagers 
		WHERE awardid = 'TSN Manager of the Year'
			AND lgid = 'NL'
		INTERSECT
		SELECT playerid
		FROM awardsmanagers 
		WHERE awardid = 'TSN Manager of the Year'
			AND lgid = 'AL')
	AND awardid = 'TSN Manager of the Year') AS winners
INNER JOIN (SELECT playerid
				, managers.yearid
				, managers.teamid
				, teams.name
			FROM managers
				LEFT JOIN teams 
				ON managers.teamid = teams.teamid
				AND managers.yearid = teams.yearid) AS team_name
ON winners.playerid = team_name.playerid
	AND winners.yearid = team_name.yearid
INNER JOIN people
ON winners.playerid = people.playerid;

-- Jim Leyland wont the TSN Manager of the Year award in both the AL and NL and won the award in 1988, 1990, 1992, and 2006 with the Pittsburgh Pirates and the Detroit Tigers. Davey Johnson also won the award in both the AL and NL and won in 1997 and 2012 with the Baltimore Orioles and the Washington Nationals. 

--10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT DISTINCT p.namefirst
	, p.namelast
	, max.hr
FROM (SELECT playerid
		, MAX(hr) AS hr
	FROM batting
	GROUP BY playerid) AS max
		LEFT JOIN batting AS b
		ON max.playerid = b.playerid
		AND max.hr = b.hr
		LEFT JOIN people AS p
		ON max.playerid = p.playerid
WHERE b.yearid = 2016
	AND max.hr > 0
	AND p.debut < '2008-03-25'
ORDER BY hr DESC;

-- There are 9 players who hit their career high number of homerunes in 2016 with Edwin Encarnacion hitting the highest with 42 homeruns.

--11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

SELECT name
	, teams.yearid
	, (SUM(salary::numeric::money) / w) AS salary_per_win
FROM teams
	LEFT JOIN salaries
	ON teams.teamid = salaries.teamid
	AND teams.yearid = salaries.yearid
WHERE teams.yearid >= 2000
GROUP BY name, teams.yearid, w
ORDER BY teams.yearid;

-- It does not seem like there is any correlation between total team salary and the amount of wins a team gets in a given season. There is a large discrepancy between the amount of salary spent per win between teams. In the early years some teams only spent around $300k per win while others spent over $1M. In the later years these numbers go up due to salary increases but there is still a large descrepancy with some teams spending around $700k per win and others spending upwards of $1.5M per win. 

-- The MVP for this project were questions 1-10 with questions 11-13 being open ended bonus questions for extra pracice. The Bonus Readme also contains more difficult bonus questions. The remaining questions will be used for practie and uploaded at a later date.