connection: "thelook_daily_updates"
label: "デモサンプル"

include: "/views/*.view.lkml"                # include all views in the views/ folder in this project
# include: "/**/*.view.lkml"                 # include all views in this project
# include: "my_dashboard.dashboard.lookml"   # include a LookML dashboard called my_dashboard

# # Select the views that should be a part of this model,
# # and define the joins that connect them together.
#
# explore: order_items {
#   join: orders {
#     relationship: many_to_one
#     sql_on: ${orders.id} = ${order_items.order_id} ;;
#   }
#
#   join: users {
#     relationship: many_to_one
#     sql_on: ${users.id} = ${orders.user_id} ;;
#   }
# }

explore: parameter_sample {
  label: "パラメーターサンプル"
  view_name: order_items

  sql_always_where:
        {% if this_date_selector._parameter_value == "dd" %}
          ${order_items.created_date} = CURRENT_DATE()
        {% elsif this_date_selector._parameter_value == "ww" %}
          ${order_items.created_week} = (FORMAT_TIMESTAMP('%F', DATE_TRUNC(CURRENT_DATE() , WEEK(MONDAY))))
        {% elsif this_date_selector._parameter_value == "mm" %}
          ${order_items.created_month} = (FORMAT_TIMESTAMP('%Y-%m', CURRENT_DATE() ))
        {% elsif this_date_selector._parameter_value == "yy" %}
          ${order_items.created_year} = EXTRACT(YEAR FROM CURRENT_DATE())
        {% else %}
          1 = 1
        {% endif %}
  ;;

  join: users {
    view_label: "顧客情報"
    sql_on: ${order_items.user_id} = ${users.id} ;;
    relationship: many_to_one
    type: left_outer
  }

  join: inventory_items {
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
    relationship: many_to_one
    type: left_outer
  }

  join: products {
    view_label: "商品情報"
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
    relationship: many_to_one
    type: left_outer
  }



}
