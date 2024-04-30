#Config file with name, title,synopsis,Home page presence, SQL query
#function to update post
#function to create new

<#

#############################
Cfg file with queries ( csv or Json)
Id, Title, query, percentage required

Pseudo code wrapper aka main
Connect to Cosmos DB
Read cfg
For each query
Search for post with query
If exist start update function
Else initialize function

Update function
Update index?
Update post
     Update card with new value and/or percentage
     Update graph
         Add li
            X=x+40
             Y= value
           Add data point
            Add tooltip $value
           Add line degree ???
               Degree=y-value

Initialize
  Create file with title name
   Add cfg to the top
   Add initial html code with values
  
   Add to index page???

#>

#Generate Name for new post
$date=$([System.Datetime]$($($N -split '-' | select -First 3) -join'-')).AddDays(-1).ToString("yyyy-MM-dd")
$PostName=$date+$PostName

