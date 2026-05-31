# Retrix Car Rental - Systems Manual

This manual provides instructions for administrators on how to operate the Retrix Car Rental management portal.

## 1. Accessing the Admin Dashboard
* Navigate to the website and click **Sign In** in the top navigation.
* Once signed in with an Administrator account, the **Admin** link will appear in the navigation bar.
* Click **Admin** to enter the management portal.

## 2. Dashboard & Reporting
The main dashboard provides a high-level overview of the business operations:
* **Key Metrics:** Total Cars, Active Bookings, Total Revenue, and Fleet Utilization rate.
* **Charts:** Monthly revenue trends and current fleet status breakdown.
* **Exporting Reports:** Click the **Export to Excel** button in the top right of the Dashboard to download a complete daily report of bookings, fleet status, and revenue.

## 3. Fleet Management (Adding/Editing Cars)
Navigate to the **Fleet** tab on the sidebar.
* **Adding a Vehicle:** Click **+ Add Vehicle**. 
  * Fill in the Make, Model, Year, Daily Rates (ZMW and USD).
  * Upload multiple photos (the first photo is the primary display image).
  * **Shuttle Service:** If a vehicle is strictly for shuttle services (custom pricing), toggle the "Shuttle Only" switch.
  * **VIN & License Plate:** Must be unique for every vehicle.
* **Editing/Deleting:** Click the pencil icon to edit an existing car, or the trash can to remove it. 

## 4. Bookings Management
Navigate to the **Bookings** tab.
* **Viewing Bookings:** All customer requests appear here. New requests are marked as **Pending**.
* **Confirming a Booking:** Click the green checkmark to confirm a booking. This changes the status to **Confirmed** and turns the customer's Quotation into a **Tax Invoice**.
* **Completing a Booking:** Once the rental period is over and the car is returned, mark it as **Completed**.
* **Viewing Documents:** Click the **View Quote/Invoice** button on any booking to open the printable PDF document containing the billing details and terms.

## 5. Site Settings (Hero Images & Video)
Navigate to the **Settings** tab.
* **Hero Video:** Upload an MP4 video or paste a URL. This video will autoplay silently in the background of the main landing page hero section. If you want to stop using the video, click "Remove Video".
* **Hero Images:** If no video is set, the system will use the Hero Images you upload here.

## 6. Offline Payments Workflow
This platform operates on a **Book Online, Pay Offline** model.
1. Customer submits a booking request online.
2. The booking sits in **Pending** status. A Quotation is generated.
3. You review the booking and click **Confirm**. The Quotation becomes a Tax Invoice.
4. The customer arrives at the office. You collect physical payment (Cash/Card/Transfer).
5. You hand over the keys. 

## 7. Damage Reports (Optional)
If a vehicle is returned with damage:
* Go to the **Damages** tab.
* Click **+ Log Damage**.
* Select the car, link the booking reference, upload photos of the damage, and enter the estimated repair cost.
* This keeps a historical record of all vehicle incidents.
