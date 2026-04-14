@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Asset Maintenance Log - Item'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true

define view entity ZI_NK_ASSET_LOG
  as select from znk_asset_log
  association to parent ZI_NK_ASSET as _Asset on $projection.asset_uuid = _Asset.asset_uuid
{
  key log_uuid,
  asset_uuid,
  service_date,
  technician,
  service_note,
  
  _Asset 
}
