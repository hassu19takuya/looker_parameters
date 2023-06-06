# The name of this view in Looker is "Order Items"
view: order_items {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `looker-private-demo.thelook.order_items`
    ;;
  drill_fields: [id]
  label: "オーダー"
  # This primary key is the unique key for this table in the underlying database.
  # You need to define a primary key in a view in order to join to other views.

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  # Dates and timestamps can be represented in Looker using a dimension group of type: time.
  # Looker converts dates and timestamps to the specified timeframes within the dimension group.

  dimension_group: created {
    label: "受注日"
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: delivered {
    label: "配達日"
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.delivered_at ;;
  }

  # Here's what a typical dimension looks like in LookML.
  # A dimension is a groupable field that can be used to filter query results.
  # This dimension will be called "Inventory Item ID" in Explore.

  dimension: inventory_item_id {
    type: number
    hidden: yes
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: order_id {
    label: "注文ID"
    type: number
    # hidden: yes
    sql: ${TABLE}.order_id ;;
  }

  dimension_group: returned {
    label: "返品日"
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.returned_at ;;
  }

  dimension: sale_price {
    label: "受注金額"
    type: number
    sql: ${TABLE}.sale_price ;;
    value_format_name: usd_0
  }

  # A measure is a field that uses a SQL aggregate function. Here are defined sum and average
  # measures for this dimension, but you can also add measures of many different aggregates.
  # Click on the type parameter to see all the options in the Quick Help panel on the right.

  measure: total_sale_price {
    label: "総受注金額"
    type: sum
    sql: ${sale_price} ;;
    value_format_name: usd_0
  }

  measure: average_sale_price {
    label: "平均受注金額"
    type: average
    sql: ${sale_price} ;;
  }

  measure: sale_users {
    label: "注文ユーザー数"
    type: count_distinct
    sql: ${user_id} ;;
  }

  measure: unit_price {
    label: "平均単価"
    type: number
    sql:  ${total_sale_price}/${count};;
    value_format_name: usd_0
  }

  dimension_group: shipped {
    label: "発送日"
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.shipped_at ;;
  }

  dimension_group: deliverly_duration {
    label: "配達リードタイム"
    type: duration
    intervals: [
      day,
      hour,
      week
      ]
    sql_start: ${created_raw} ;;
    sql_end: ${delivered_raw} ;;
  }

  measure: average_deliverly_leadtime {
    label: "平均配達リードタイム(日)"
    type: number
    sql: ${delivered_date} ;;
  }

  dimension: status_eng {
    hidden: yes
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: status {
    label: "ステータス"
    type: string
    sql:
      CASE
        WHEN ${status_eng} = 'Processing' THEN 'プロセス中'
        WHEN ${status_eng} = 'Shipped' THEN '出荷'
        WHEN ${status_eng} = 'Complete' THEN '完了'
        WHEN ${status_eng} = 'Returned' THEN '返品'
        WHEN ${status_eng} = 'Cancelled' THEN 'キャンセル'
        ELSE null
      END ;;
  }

  dimension: user_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  # ----- Sets of fields for drilling ------
  set: detail {
    fields: [
      id,
      users.last_name,
      users.id,
      users.first_name,
      inventory_items.id,
      inventory_items.product_name,
      orders.order_id
    ]
  }
}

## パラメーターなど拡張した内容をこちらに入れ、本来のテーブル定義と分けて管理する
view: +order_items {

  ## 期間選択用の入力フィールド作成
  parameter: this_date_selector {
    label: "当期間"
    description: "カレンダーで選ばずとも選択した期間で自動的にフィルターがかかるようにする選択肢"
    type: unquoted
    allowed_value: {
      label: "当日"
      value: "dd"
    }
    allowed_value: {
      label: "当週"
      value: "ww"
    }
    allowed_value: {
      label: "当月"
      value: "mm"
    }
    allowed_value: {
      label: "当年"
      value: "yy"
    }
  }
  ## 期間選択用入力フィールドの値に合わせて選択期間を計算
  dimension: this_date {
    label: "当期間"
    description: "パラメーターと同時利用で機能します"
    sql:
        {% if this_date_selector._parameter_value == "dd" %}
          CURRENT_DATE()
        {% elsif this_date_selector._parameter_value == "ww" %}
          (FORMAT_TIMESTAMP('%F', DATE_TRUNC(CURRENT_DATE() , WEEK(MONDAY))))
        {% elsif this_date_selector._parameter_value == "mm" %}
          (FORMAT_TIMESTAMP('%Y-%m', CURRENT_DATE() ))
        {% elsif this_date_selector._parameter_value == "yy" %}
          EXTRACT(YEAR FROM CURRENT_DATE())
        {% else %}
          "未選択"
        {% endif %}
    ;;
  }

  ## 集計日付単位の選択フィールド作成
  parameter: date_granularity_selector {
    label: "日付粒度"
    description: "日付粒度dimensionの集計単位を選択するためのパラメーター選択値"
    type: unquoted
    allowed_value: {
      label: "日"
      value: "day"
    }
    allowed_value: {
      label: "週"
      value: "week"
    }
    allowed_value: {
      label: "月"
      value: "month"
    }
    allowed_value: {
      label: "年"
      value: "year"
    }
  }
  ## 集計日付単位に合わせて表示される内容が可変するdimension
  dimension: data_guranularity {
    label: "日付粒度"
    description: "パラメーターと同時利用で機能します"
    sql:
        {% if date_granularity_selector._parameter_value == "day" %}
          ${created_date}
        {% elsif date_granularity_selector._parameter_value == "week" %}
          ${created_week}
        {% elsif date_granularity_selector._parameter_value == "month" %}
          ${created_month}
        {% elsif date_granularity_selector._parameter_value == "year" %}
          ${created_year}
        {% endif %}
    ;;
  }

  ## 可変軸の一つ目の選択
  parameter: dimension1_selector {
    label: "選択軸1"
    type: unquoted
    allowed_value: {
      label: "ステータス"
      value: "status"
    }
    allowed_value: {
      label: "性別"
      value: "gender"
    }
    allowed_value: {
      label: "年齢層"
      value: "age_tier"
    }
    allowed_value: {
      label: "州"
      value: "state"
    }
    allowed_value: {
      label: "流入経路"
      value: "source"
    }
    allowed_value: {
      label: "ブランド"
      value: "brand"
    }
    allowed_value: {
      label: "カテゴリ"
      value: "category"
    }
    allowed_value: {
      label: "商品名"
      value: "item_name"
    }
  }
  ## 可変軸1の選択に合わせて取得元dimensionを変更
  dimension: selected_dimension_1 {
    label: "選択軸1"
    description: "パラメーターと同時利用で機能します"
    sql:
        {% if dimension1_selector._parameter_value == "status" %}
          ${status}
        {% elsif dimension1_selector._parameter_value == "gender" %}
          ${users.gender}
        {% elsif dimension1_selector._parameter_value == "age_tier" %}
          ${users.age_tier}
        {% elsif dimension1_selector._parameter_value == "state" %}
          ${users.state}
        {% elsif dimension1_selector._parameter_value == "source" %}
          ${users.traffic_source}
        {% elsif dimension1_selector._parameter_value == "brand" %}
          ${products.brand}
        {% elsif dimension1_selector._parameter_value == "category" %}
          ${products.category}
        {% elsif dimension1_selector._parameter_value == "item_name" %}
          ${products.name}
        {% else %}
          "未選択"
        {% endif %}
    ;;
  }

  ## 可変軸の2つ目の選択
  parameter: dimension2_selector {
    label: "選択軸2"
    type: unquoted
    allowed_value: {
      label: "ステータス"
      value: "status"
    }
    allowed_value: {
      label: "性別"
      value: "gender"
    }
    allowed_value: {
      label: "年齢層"
      value: "age_tier"
    }
    allowed_value: {
      label: "州"
      value: "state"
    }
    allowed_value: {
      label: "流入経路"
      value: "source"
    }
    allowed_value: {
      label: "ブランド"
      value: "brand"
    }
    allowed_value: {
      label: "カテゴリ"
      value: "category"
    }
    allowed_value: {
      label: "商品名"
      value: "item_name"
    }
  }

  ## 可変軸2の選択に合わせて取得元dimensionを変更
  dimension: selected_dimension_2 {
    label: "選択軸2"
    description: "パラメーターと同時利用で機能します"
    sql:
        {% if dimension2_selector._parameter_value == "status" %}
          ${status}
        {% elsif dimension2_selector._parameter_value == "gender" %}
          ${users.gender}
        {% elsif dimension2_selector._parameter_value == "age_tier" %}
          ${users.age_tier}
        {% elsif dimension2_selector._parameter_value == "state" %}
          ${users.state}
        {% elsif dimension2_selector._parameter_value == "source" %}
          ${users.traffic_source}
        {% elsif dimension2_selector._parameter_value == "brand" %}
          ${products.brand}
        {% elsif dimension2_selector._parameter_value == "category" %}
          ${products.category}
        {% elsif dimension2_selector._parameter_value == "item_name" %}
          ${products.name}
        {% else %}
          "未選択"
        {% endif %}
    ;;
  }

  ## 可変集計値の選択
  parameter: measure_selector {
    label: "選択集計値"
    type: unquoted
    allowed_value: {
      label: "受注額"
      value: "sales"
    }
    allowed_value: {
      label: "注文数"
      value: "orders"
    }
    allowed_value: {
      label: "平均受注額"
      value: "avg_sales"
    }
    allowed_value: {
      label: "ユーザー数"
      value: "uu"
    }
  }

  ## 可変軸2の選択に合わせて取得元dimensionを変更
  measure: selected_measure {
    label: "選択集計値"
    description: "パラメーターと同時利用で機能します"
    type: number
    sql:
        {% if measure_selector._parameter_value == "sales" %}
          ${total_sale_price}
        {% elsif measure_selector._parameter_value == "orders" %}
          ${count}
        {% elsif measure_selector._parameter_value == "avg_sales" %}
          ${average_sale_price}
        {% elsif measure_selector._parameter_value == "uu" %}
          ${sale_users}
        {% endif %}
    ;;
  }



}
