CLASS zcl_nk_init_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_nk_init_data IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

  DELETE FROM znk_asset_hdr.
    DELETE FROM znk_asset_log.

    INSERT znk_asset_hdr FROM TABLE @( VALUE #(
      ( asset_uuid = cl_system_uuid=>create_uuid_x16_static( ) asset_id = 'IT-001' description = 'MacBook Pro' category = 'Laptop' overall_status = 'N' )
      ( asset_uuid = cl_system_uuid=>create_uuid_x16_static( ) asset_id = 'IT-002' description = 'Dell Monitor' category = 'Display' overall_status = 'U' )
      ( asset_uuid = cl_system_uuid=>create_uuid_x16_static( ) asset_id = 'IT-003' description = 'HP Printer' category = 'Office' overall_status = 'R' )
    ) ).

    out->write( 'Success: Demo assets created!' ).
  ENDMETHOD.
ENDCLASS.
