CLASS lhc_Asset DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Asset RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Asset RESULT result.

    METHODS SetToInUse FOR MODIFY
      IMPORTING keys FOR ACTION Asset~SetToInUse RESULT result.

    METHODS SendToRepair FOR MODIFY
      IMPORTING keys FOR ACTION Asset~SendToRepair RESULT result.

    METHODS Decommission FOR MODIFY
      IMPORTING keys FOR ACTION Asset~Decommission RESULT result.

    METHODS SetInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Asset~SetInitialStatus.

    METHODS validatePurchaseDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Asset~validatePurchaseDate.

    METHODS calculateValuation FOR DETERMINE ON SAVE
      IMPORTING keys FOR Asset~calculateValuation.
ENDCLASS.

CLASS lhc_Asset IMPLEMENTATION.

  METHOD get_global_authorizations.
    result = VALUE #( %create = if_abap_behv=>auth-allowed
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
      ENTITY Asset FIELDS ( OverallStatus ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    result = VALUE #( FOR asset IN assets (
        %tky = asset-%tky
        " Set to In Use: Enabled for New (N) or returning from Repair (R)
        %action-SetToInUse  = COND #( WHEN asset-OverallStatus = 'N' OR asset-OverallStatus = 'R' OR asset-OverallStatus IS INITIAL
                                      THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )

        " Send to Repair: Only enabled if currently In Use (U)
        %action-SendToRepair = COND #( WHEN asset-OverallStatus = 'U'
                                       THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )

        " Decommission: Enabled for any status EXCEPT already Scrapped (S)
        %action-Decommission = COND #( WHEN asset-OverallStatus <> 'S'
                                       THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
      ) ).
  ENDMETHOD.

  METHOD SetToInUse.
    MODIFY ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
      ENTITY Asset
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky OverallStatus = 'U' ) )
      ENTITY Asset
        CREATE BY \_Logs
        FIELDS ( service_date technician service_note )
        WITH VALUE #( FOR key IN keys (
                         %tky = key-%tky
                         %target = VALUE #( ( %cid = |U_LOG_{ sy-uzeit }|
                                              service_date = cl_abap_context_info=>get_system_date( )
                                              technician   = sy-uname
                                              service_note = 'Asset active: Returned to operational state.' ) ) ) )
    FAILED failed REPORTED reported.

    READ ENTITIES OF ZI_NK_ASSET IN LOCAL MODE ENTITY Asset ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(assets).
    result = VALUE #( FOR asset IN assets ( %tky = asset-%tky %param = asset ) ).
  ENDMETHOD.

  METHOD SendToRepair.
    MODIFY ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
      ENTITY Asset
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky OverallStatus = 'R' ) )
      ENTITY Asset
        CREATE BY \_Logs
        FIELDS ( service_date technician service_note )
        WITH VALUE #( FOR key IN keys (
                         %tky = key-%tky
                         %target = VALUE #( ( %cid = |R_LOG_{ sy-uzeit }| " FIX: Added Timestamp to avoid Dump
                                              service_date = cl_abap_context_info=>get_system_date( )
                                              technician   = 'MAINTENANCE'
                                              service_note = 'Maintenance Required: Sent to repair facility.' ) ) ) )
    FAILED failed REPORTED reported.

    READ ENTITIES OF ZI_NK_ASSET IN LOCAL MODE ENTITY Asset ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(assets).
    result = VALUE #( FOR asset IN assets ( %tky = asset-%tky %param = asset ) ).
  ENDMETHOD.

  METHOD Decommission.
    MODIFY ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
      ENTITY Asset
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky OverallStatus = 'S' ) )
      ENTITY Asset
        CREATE BY \_Logs
        FIELDS ( service_date technician service_note )
        WITH VALUE #( FOR key IN keys (
                         %tky = key-%tky
                         %target = VALUE #( ( %cid = |S_LOG_{ sy-uzeit }| " FIX: Added Timestamp to avoid Dump
                                              service_date = cl_abap_context_info=>get_system_date( )
                                              technician   = 'FINANCE'
                                              service_note = 'Asset Scrapped: End of lifecycle reached.' ) ) ) )
    FAILED failed REPORTED reported.

    READ ENTITIES OF ZI_NK_ASSET IN LOCAL MODE ENTITY Asset ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(assets).
    result = VALUE #( FOR asset IN assets ( %tky = asset-%tky %param = asset ) ).
  ENDMETHOD.

  METHOD validatePurchaseDate.
  READ ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
    ENTITY Asset FIELDS ( PurchaseDate ) WITH CORRESPONDING #( keys )
    RESULT DATA(assets).

  DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

  LOOP AT assets INTO DATA(asset).
    IF asset-PurchaseDate > lv_today.
      APPEND VALUE #( %tky = asset-%tky ) TO failed-asset.
      APPEND VALUE #( %tky = asset-%tky
                      %msg = New_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = 'Purchase date cannot be in the future' )
                      %element-PurchaseDate = if_abap_behv=>mk-on ) TO reported-asset.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

METHOD calculateValuation.
  READ ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
    ENTITY Asset FIELDS ( PurchasePrice ) WITH CORRESPONDING #( keys )
    RESULT DATA(assets).

  MODIFY ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
    ENTITY Asset
      UPDATE FIELDS ( CurrentValue ScrapLossAmount )
      WITH VALUE #( FOR asset IN assets (
                       %tky              = asset-%tky
                       CurrentValue      = asset-PurchasePrice * '0.85'
                       ScrapLossAmount   = asset-PurchasePrice * '0.15' ) )
  REPORTED DATA(lt_reported).
ENDMETHOD.

  METHOD SetInitialStatus.
    " This determination ensures every 'New' object starts with status 'N'
    MODIFY ENTITIES OF ZI_NK_ASSET IN LOCAL MODE
      ENTITY Asset
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky OverallStatus = 'N' ) )
    REPORTED DATA(reported_status).
    reported = CORRESPONDING #( DEEP reported_status ).
  ENDMETHOD.

ENDCLASS.
