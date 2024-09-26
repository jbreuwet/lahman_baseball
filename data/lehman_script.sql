-- 1. 
SELECT COUNT(DISTINCT year)
FROM homegames;
-- 146 years covered by the database

--2. 
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

--3. 
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

--4. 
SELECT CASE WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
			WHEN pos IN ('P','C') THEN 'Battery' END AS position
	, SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position;
-- In 2016, the infield positions had a total of 58,934 putouts, the battery had a total of 41,424 putouts, and the outfield had a total of 29560 putouts.

--6. 
SELECT namefirst
	, namelast
	, ROUND(SUM(sb::numeric) / (SUM(sb::numeric) + SUM(cs::numeric)) * 100, 2) AS stealing_success
FROM people
	INNER JOIN batting
	USING(playerid)
WHERE yearid = 2016
GROUP BY namefirst, namelast
HAVING (SUM(sb) + SUM(cs)) >= 20
ORDER BY stealing_success DESC;
-- In 2016, Chris Owings had the best succes stealing bases with a 91.3% success rate.

--7.
SELECT name
	, SUM(w) AS total_wins
FROM teams
WHERE name IN
	(SELECT DISTINCT name
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	EXCEPT
	SELECT DISTINCT name
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y')
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name
ORDER BY total_wins DESC;
-- The largest number of wins between 1970 and 2016 for a team that did not win the world series is 3735 with the Houston Astros.

SELECT name
	, SUM(w) AS total_wins	
FROM teams
WHERE name IN
	(SELECT DISTINCT name
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y')
	AND yearid BETWEEN 1970 AND 2016
	AND name <> 'Anaheim Angels'
GROUP BY name
ORDER BY total_wins;
-- The least amount of wins between 1970 and 2016 for a team that did win the world series is 1435 with the Florida Marlins. The Anaheim Angels were removed for they only played a small amount of years during this time period.

SELECT ROUND((COUNT(won)::numeric / COUNT(loss)::numeric) * 100, 2) AS prct_win
FROM (SELECT CASE WHEN teams.wswin = 'Y' THEN 'won' END AS won
		, CASE WHEN teams.wswin = 'N' OR teams.wswin IS NULL THEN 'loss' END AS loss
	FROM (SELECT yearid
				, MAX(w) AS w
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016
		GROUP BY yearid) AS max_wins
			LEFT JOIN teams
			ON max_wins.yearid = teams.yearid
			AND max_wins.w = teams.w)
-- The team with the highest amount of wins during a given season only won the world series 29.27% of the time. 
	
--9. 
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

--10. 
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
	AND p.debut < '2008-03-25';
-- 9 players hit their career high number of homerunes in 2016 with Edwin Encarnacion hitting the highest with 42 homeruns.

--11. 
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