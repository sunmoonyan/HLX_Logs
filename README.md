# HLX_Logs

HLX_Logs is an in-game logging interface designed to make server log consultation fast, intuitive, and powerful.
Instead of digging through files, you can access and filter logs instantly using a dedicated command and advanced search tools.

# 🚀 Features
Open the log interface at any time using the command:

![preview](https://i.ibb.co/5hgDrQky/Screenshot-From-2026-03-17-14-09-28.png)
![preview](https://i.ibb.co/wZxtqGrh/Screenshot-From-2026-03-17-14-08-16.png)
![preview](https://i.ibb.co/yBy77Nhd/Screenshot-From-2026-03-17-14-08-44.png)

# 🔍 Advanced Filtering System

HLX_Logs provides a powerful filtering system to precisely target the logs you need.


Search using: Keywords, Player names (pseudo), Time

Exemple with "observer"

![preview](https://i.ibb.co/5XFrQPzL/Screenshot-From-2026-03-17-14-09-05.png)


# ⚙️ Logical Operators

Refine your searches using logical operators:
  & → AND
  | → OR

Example:

  sunshi&observer|bot
  (Shows logs containing sunshi AND observer OR bot)

This allows for complex and highly specific queries.

Filter logs by a specific time window using the [TIME] tag:

  [TIME:HH:MM-HH:MM]

Example:

  [TIME:13:00-14:00] (Displays only logs between 1 PM and 2 PM)
  Works in combination with other filters
