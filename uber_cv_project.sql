create database uber_project;
use uber_project;
/*load data local infile 'C:\\Users\\AYANTIKA CHOWDHURY\\Desktop\\ride.csv'
into table ride FIELDS TERMINATED BY ','  
enclosed by '"' lines terminated by '\n' ignore 1 rows;*/

create table ride
( Booking_Date	Char(100),
Booking_Time	Char(100),
BookingID	Char(100),
Booking_Status	Char(100),
CustomerID	Char(100),
Vehicle_Type	Char(100),
Pickup_Location	Char(100),
Drop_Location	Char(100),
Avg_VTAT	int,
Avg_CTAT	int,
Customer_cancellation_reason	Char(100),
Driver_Cancellation_Reason	Char(100),
Incomplete_Rides_Reason	Char(100),
BookingValue	int,
RideDistance	int,
CustomerRating	int,
PaymentMethod Char(100));

select * from ride;

												

ALTER TABLE ride
ADD COLUMN booking_date_new DATE;

ALTER TABLE ride
ADD COLUMN booking_time_new TIME;

UPDATE ride
SET booking_time_new = STR_TO_DATE(booking_time, '%H:%i:%s');

SET SQL_SAFE_UPDATES = 0;

alter table ride
drop column booking_time_new;

/*1. Top 10 pickup_location by total_revenue*/

select pickup_location,sum(bookingvalue) as total_revenue
from ride 
where booking_status="completed"
group by pickup_location
order by 2 desc
limit 10;


/*2. Payment method wise revenue contribution */

select paymentmethod,round((sum(bookingvalue)*100)/sum(sum(bookingvalue))over(),2) as rev_perc,sum(bookingvalue) as Revenue
from ride
where booking_status="completed"
group by paymentmethod;

/*3. Payment method wise completed rides*/

select paymentmethod,count(bookingid) as no_of_completedrides
from ride
where booking_status="completed"
group by paymentmethod
order by 2 desc;

/*4 Number of  daily bookings*/

select booking_date_new,count(bookingid) as NoOfBookingsDaily
from ride
where booking_status="completed"
group by booking_date_new;

/* 5. avg daily daily booking*/

select round(avg(NoOfBookingsDaily),2)
from(select booking_date_new,count(bookingid) as NoOfBookingsDaily
from ride
where booking_status="completed"
group by booking_date_new) as AB;

/*6. find peak hrs */

select hour(booking_time_new) as booking_hour, count(bookingid) as NoOfBookings
from ride
where booking_status="completed"
group by hour(booking_time_new)
order by 1
;

/*7. Find top 10 high-demand days*/

select booking_date_new,count(bookingid) as NoOfBookingsDaily
from ride
where booking_status="completed" 
group by booking_date_new

having count(bookingid)>(select round(avg(NoOfBookingsDaily),2)
from(select booking_date_new,count(bookingid) as NoOfBookingsDaily
from ride
where booking_status="completed"
group by booking_date_new) as AB)
order by 2 desc
limit 10;

/*8. During high-demand days, which hours experience the highest booking volume? */

select hour(booking_time_new) as booking_hour,count(bookingid) as noOFbookings
from ride
where booking_status="completed"
and booking_date_new in (select booking_date_new
from ride
where booking_status="completed" 
group by booking_date_new

having count(bookingid)>(select round(avg(NoOfBookingsDaily),2)
from(select booking_date_new,count(bookingid) as NoOfBookingsDaily
from ride
where booking_status="completed"
group by booking_date_new) as AB))

group by hour(booking_time_new)
order by 1;

/*9.	Monthly bookings & revenue trend*/

select month(booking_date_new),monthname(booking_date_new),count(bookingid) as noOFbookings,sum(bookingvalue) as totalRevenue
from ride
where booking_status="completed"
group by month(booking_date_new),monthname(booking_date_new)
order by 1;



/*10. show Top 5 customer id in terms of  number of completed rides*/

select customerid,count(*) as noOFcompletedrides
from ride
where booking_status="completed"
group by customerid
order by 2 desc
limit 5;

/*11. Different Reasons behind ride cancellation by customer and their counts */
select Customer_cancellation_reason,count(*) as count 
from ride
where Customer_cancellation_reason<>"null"
group by Customer_cancellation_reason
order by 2 desc;

/*12. Different reasons behind ride cancellation by driver and their counts */
select driver_cancellation_reason,count(*) as count 
from ride
where driver_cancellation_reason<>"null"
group by driver_cancellation_reason
order by 2 desc;

/*13. Which pickup locations have the highest driver-cancellation rate?*/

select pickup_location, count(bookingid) as noOfBookings,(sum(if(booking_status="cancelled by driver",1,0))/sum(if(booking_status in ("cancelled by driver","cancelled by customer","completed"),1,0)))*100 as driver_cancellation_rate
from ride
group by pickup_location
order by 3 desc
limit 5;

/*14. which vehicle has highest no of bookings*/

select vehicle_type,count(*) as noOFbookings
from ride
where booking_status="completed"
group by vehicle_type;

/*15. which vehicle generate highest revenue*/

select vehicle_type,sum(bookingvalue) as TotalRevenue
from ride
where booking_status="completed"
group by vehicle_type;

/*16. For each pickup location, which hour has the highest booking demand*/

with cte as( select pickup_location, hour(booking_time_new) as peakHour,count(bookingid) as noOfBookings,
            row_number() over (partition by pickup_location order by count(bookingid) desc) as demand_rank
from ride
group by pickup_location,hour(booking_time_new))
 
 
 select pickup_location,peakHour, noOfBookings 
 from cte
 where demand_rank in(1);
 
/* 17. What proportion of customers are repeat users */

select  round( (sum(if(completed_rides<>1,1,0)) 
        / count(*)*100),2) AS repeat_customer_percentage
FROM
(select customerID,count(bookingID) as completed_rides
from ride
where Booking_Status = 'completed'
group by customerID) as customer_summary;

/*18.  Total number of repeat customers*/

with c as (select customerID,count(bookingID) as completed_rides
from ride
where Booking_Status = 'completed'
group by customerID
order by 2 desc)

select count(*) from c where completed_rides<>1;




