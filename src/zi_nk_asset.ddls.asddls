@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Asset Management - Root'
@Metadata.allowExtensions: true

define root view entity ZI_NK_ASSET
  as select from znk_asset_hdr
  composition [0..*] of ZI_NK_ASSET_LOG as _Logs
{
  key asset_uuid,
  asset_id        as AssetId,
  description     as Description,
  category        as Category,
  purchase_date   as PurchaseDate,
  
  @Semantics.amount.currencyCode: 'Currency'
  purchase_price  as PurchasePrice,
  
  currency        as Currency,
  overall_status  as OverallStatus,
  
  @EndUserText.label: 'Status Color'
  case overall_status
    when 'R' then 1
    when 'S' then 1
    when 'U' then 3
    when 'N' then 2
    else 0 
  end as StatusCriticality,

  @EndUserText.label: 'Asset Age (Days)'
  dats_days_between(purchase_date, $session.system_date) as AssetAgeDays,

  @Semantics.amount.currencyCode: 'Currency'
  @EndUserText.label: 'Current Valuation'
  cast( cast( purchase_price as abap.dec(15,2) ) * cast( '0.85' as abap.dec(3,2) ) as abap.curr(15,2) ) as CurrentValue,
  
  @Semantics.amount.currencyCode: 'Currency'
  @EndUserText.label: 'Scrap Loss'
  cast( cast( purchase_price as abap.dec(15,2) ) * cast( '0.85' as abap.dec(3,2) ) as abap.curr(15,2) ) as ScrapLossAmount,
  
  last_changed_at,
  _Logs
}
