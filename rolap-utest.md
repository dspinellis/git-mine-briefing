<!-- vim: fileencoding=utf-8
-->
## Real-world queries can be complex
![SQL query dependency graph](a/graph.png)

(2600 lines of SQL)

---
## Real-world queries can be expensive
```
Jan 21 12:22 user_pull_request_activity
Jan 21 12:58 user_combined_activity
[29 lines removed]
Jan 21 14:40 new_members
Jan 21 14:40 nl_commit_comments
Jan 21 17:56 nl_commits
Jan 21 20:52 nl_issue_comments
[10 lines removed]
Jan 21 21:49 nl_pull_request_comments
Jan 22 00:08 nl_user_combined_activity
[12 lines removed]
Jan 22 02:04 leader_project_performance
Jan 22 02:05 lines_per_commit
```

---
## What can we do?
* Modularize
  * Incremental construction
  * Unit testing
  * Execution checkpoints
  * Reuse

---
## Approaches
* Oracle/DB2/PostgreSQL/... materialized views
* Justin Swanhart's MySQL [Flexviews](https://github.com/greenlion/swanhart-tools)
* Make-based [simple-rolap](https://github.com/dspinellis/simple-rolap)

---
## Example task
1. Choose repositories that have forks (_A_)
2. from _A_, exclude repos that where inactive _recently_ (_B_)
2. from _B_, exclude repos that never received a PR (_C_)

On _C_, we can then apply further criteria (e.g. programming language,
build system, minimum number of stars etc).

---
## Environment setup
* Clone and install [github.com/dspinellis/rdbunit](https://github.com/dspinellis/rdbunit)
* Clone [github.com/dspinellis/simple-rolap](https://github.com/dspinellis/simple-rolap)

---
## Project setup
Create a `Makefile` with the following contents:
```Makefile
export RDBMS?=sqlite
export MAINDB?=rxjs-ghtorrent
export ROLAPDB?=driveby
export DEPENDENCIES=rxjs-ghtorrent.db

include ../../Makefile

rxjs-ghtorrent.db:
        wget https://github.com/ghtorrent/tutorial/raw/master/rxjs-ghtorrent.db
```

---
## Repositories with forks
Create a file `forked_projects.sql`
```sql
-- Projects that have been forked

create table driveby.forked_projects AS
  select distinct forked_from as id from projects;
```

---
## Run it
```sh
$ make
rm -f ./.depend
sh ../..//mkdep.sh >./.depend
mkdir -p tables
sh ../..//run_sql.sh forked_projects.sql >tables/forked_projects
```

---
## Run it again
```sh
$ make
make: Nothing to be done for 'all'.
```

---
## Yes, but is it correct?
Create a file `forked_projects.rdbu`
```
BEGIN SETUP

projects:
id      forked_from
1       15
2       15
3       10
4       NULL

END

INCLUDE CREATE forked_projects.sql

BEGIN RESULT
driveby.forked_projects:
id
15
10
END
```

---
## Run the tests
```
$ make test
../..//run_test.sh
not ok 1 - forked_projects.rdbu: test_driveby.forked_projects
1..1
```

Houston, we have a problem!

---

---
## Step-by--step debugging
```
$ rdbunit --database=sqlite forked_projects.rdbu >script.sql
$ sqlite3
SQLite version 3.8.7.1 2014-10-29 13:59:56
sqlite> .read script.sql
not ok 1 - forked_projects.rdbu: test_driveby.forked_projects
1..1

sqlite> select * from test_driveby.forked_projects;
15
10

sqlite> select count(*) from test_driveby.forked_projects;
3
```

---
## Correct the error
```sql
-- Projects that have been forked

create table driveby.forked_projects AS
  select distinct forked_from as id from projects
  where forked_from is not null;
```

---
## Test again
```
$ make test
rm -f ./.depend
sh ../..//mkdep.sh >./.depend
../..//run_test.sh
ok 1 - forked_projects.rdbu: test_driveby.forked_projects
1..1
```

Bingo!

