# The name of this view in Looker is "Products"
view: products {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `looker-private-demo.thelook.products`
    ;;
  drill_fields: [id]
  # This primary key is the unique key for this table in the underlying database.
  # You need to define a primary key in a view in order to join to other views.

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  # Here's what a typical dimension looks like in LookML.
  # A dimension is a groupable field that can be used to filter query results.
  # This dimension will be called "Brand" in Explore.

  dimension: brand {
    label: "ブランド"
    type: string
    sql: ${TABLE}.brand ;;
  }

  dimension: category {
    label: "カテゴリ"
    type: string
    sql: ${TABLE}.category ;;
  }

  dimension: cost {
    label: "原価"
    type: number
    sql: ${TABLE}.cost ;;
  }

  # A measure is a field that uses a SQL aggregate function. Here are defined sum and average
  # measures for this dimension, but you can also add measures of many different aggregates.
  # Click on the type parameter to see all the options in the Quick Help panel on the right.

  measure: total_cost {
    label: "総原価"
    type: sum
    sql: ${cost} ;;
  }

  measure: average_cost {
    label: "平均原価"
    type: average
    sql: ${cost} ;;
  }

  dimension: department {
    label: "取扱部署"
    type: string
    sql: ${TABLE}.department ;;
  }

  dimension: distribution_center_id {
    hidden: yes
    type: string
    sql: ${TABLE}.distribution_center_id ;;
  }

  dimension: name {
    label: "商品名"
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: retail_price {
    label: "定価"
    type: number
    sql: ${TABLE}.retail_price ;;
  }

  dimension: sku {
    type: string
    sql: ${TABLE}.sku ;;
  }

  measure: count {
    label: "商品数"
    type: count
    drill_fields: [id, name, inventory_items.count]
  }
}
