USE DATABASE tb_101;
USE ROLE accountadmin;
USE WAREHOUSE my_wh;
SELECT
    o.truck_brand_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(o.price) AS total_sales
FROM analytics.orders_v o
GROUP BY o.truck_brand_name
ORDER BY total_sales DESC;
/*
    <SQLワークシート利用時>
    結果パネルを開いて、右上のツールバーを見てください。ここには検索、列選択、クエリ詳細と
    実行時間統計の表示、列統計の表示、結果のダウンロードのオプションがあります。
    
    検索 - 検索語句を使用して結果をフィルタリング
    結果の列を選択 - 結果に表示する列を有効/無効にする
    クエリの詳細 - SQLテキスト、返された行数、クエリID、実行されたロールとウェアハウスなど、
                クエリに関連する情報が含まれます。
    クエリ期間 - コンパイル時間、プロビジョニング時間、実行時間によってクエリの
                    実行にかかった時間を分析します。
    列統計 - 結果パネルの列の分布に関するデータを表示します。
    結果ダウンロード - 結果をCSVとしてエクスポート・ダウンロードします。
*/