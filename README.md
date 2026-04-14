# ASSET_MANAGEMENT

Asset Management System - SAP BTP RAP Project
Description
This project is a full-stack Asset Management Application built on the SAP ABAP RESTful Programming Model (RAP). It is designed to track the lifecycle of corporate assets—from procurement to decommissioning. The system automatically calculates asset depreciation and age while maintaining a strict audit trail (Maintenance History) for every status change.

Key Features
Automated Financial Math: Real-time calculation of Current Valuation (85%) and Scrap Loss (15%).

Asset Lifecycle Workflow: Managed state transitions (New → In Use → Repair → Scrapped).

Audit Logging: Automatic creation of maintenance logs during status changes.

Draft Support: "Save as draft" functionality to prevent data loss during editing.

Visual Criticality: Color-coded status indicators (Red/Yellow/Green) for at-a-glance monitoring.

Workflow Logic
The application follows a strictly defined business logic flow to ensure data integrity:

Procurement: Asset is created with status New (N).

Deployment: User clicks "Set to In Use", changing status to In Use (U) and logging the activation date.

Maintenance: If an asset fails, it is moved to Repair (R).

Resolution: - If fixed, it returns to In Use (U).

If unrepairable, it is moved to Scrapped (S).

Decommissioning: Assets can be moved to Scrapped (S) from any state, triggering a final valuation loss log.

Step-by-Step Development Process
To recreate this project from scratch, follow these steps in order:

1. Database Layer (The Foundation)
Create the persistent tables and their corresponding draft tables.

znk_asset_hdr: Stores core asset data (ID, Price, Purchase Date).

znk_asset_log: Stores the maintenance history entries.

znk_asset_draft & znk_log_draft: Mandatory tables for the RAP Draft mechanism.

2. Data Modeling (CDS Views)
Define the business entities and calculations.

Root View (ZI_NK_ASSET): Contains the dats_days_between logic for age and cast expressions for the 85%/15% price split.

Child View (ZI_NK_ASSET_LOG): Associated with the root to show history.

3. Behavior Definition (BDEF)
Define what the system can do.

Enable with draft.

Define actions (SetToInUse, SendToRepair, Decommission).

Define determinations (Calculate valuation on save).

Define validations (Prevent future purchase dates).

4. Behavior Implementation (ABAP Class)
Write the logic for the buttons and automated logging in the behavior pool class ZBP_I_NK_ASSET.

get_instance_features: Controls which buttons are clickable based on the current status.

MODIFY ENTITIES: Handles the database updates and automatic creation of child log records.

5. UI & Service Layer
Metadata Extension (MDE): Use @UI annotations to define the Fiori layout, labels, and button placements.

Service Definition: Expose the views.

Service Binding: Bind to OData V2/V4 for the Fiori Elements Preview.

Code Logic Highlights

Automated Valuation Calculation

// Calculated in the CDS View for real-time display
@Semantics.amount.currencyCode: 'Currency'
cast( cast( purchase_price as abap.dec(15,2) ) * cast( '0.85' as abap.dec(3,2) ) as abap.curr(15,2) ) as CurrentValue


Action Visibility Logic

// Logic to ensure an asset must be 'In Use' before it can be 'Repaired'
%action-SendToRepair = COND #( WHEN asset-OverallStatus = 'U'
                               THEN if_abap_behv=>fc-o-enabled 
                               ELSE if_abap_behv=>fc-o-disabled )


**How to Run the Code**

Clone & Import: Import the objects into your ABAP Package via ADT (Eclipse).

Schema Setup: Run the provided SQL/Data definitions to create the znk tables.

Activation: Select all objects and use Ctrl+F3 to mass-activate (ensuring Draft tables are activated first).

Service Binding: Navigate to the Service Binding object and click Publish.

Preview: Select the Asset entity and click Preview to launch the Fiori Elements app.


                               
