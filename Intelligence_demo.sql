----------------------------------------------------------------------
-- Snowflake Intelligence セットアップ
----------------------------------------------------------------------

-- Step 1: ロールとウェアハウスの設定
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Step 2: デモ用データベース・スキーマの作成
CREATE DATABASE IF NOT EXISTS INTELLIGENCE_DEMO_DB;
CREATE SCHEMA IF NOT EXISTS INTELLIGENCE_DEMO_DB.DEMO;

-- Step 3: サンプルテーブルの作成とデータ投入
CREATE OR REPLACE TABLE INTELLIGENCE_DEMO_DB.DEMO.PRODUCTS (
    PRODUCT_ID INT,
    PRODUCT_NAME VARCHAR,
    CATEGORY VARCHAR,
    PRICE NUMBER(10,2)
);

INSERT INTO INTELLIGENCE_DEMO_DB.DEMO.PRODUCTS VALUES
    (1, 'Laptop', 'Electronics', 120000),
    (2, 'Headphones', 'Electronics', 15000),
    (3, 'Desk Chair', 'Furniture', 45000),
    (4, 'Monitor', 'Electronics', 60000),
    (5, 'Standing Desk', 'Furniture', 80000),
    (6, 'Keyboard', 'Electronics', 8000),
    (7, 'Webcam', 'Electronics', 12000),
    (8, 'Bookshelf', 'Furniture', 25000);

CREATE OR REPLACE TABLE INTELLIGENCE_DEMO_DB.DEMO.SALES (
    SALE_ID INT,
    PRODUCT_ID INT,
    SALE_DATE DATE,
    QUANTITY INT,
    REGION VARCHAR
);

INSERT INTO INTELLIGENCE_DEMO_DB.DEMO.SALES VALUES
    (1, 1, '2025-01-15', 5, 'Tokyo'),
    (2, 2, '2025-01-20', 20, 'Osaka'),
    (3, 3, '2025-02-10', 8, 'Tokyo'),
    (4, 4, '2025-02-14', 12, 'Nagoya'),
    (5, 1, '2025-03-01', 3, 'Osaka'),
    (6, 5, '2025-03-15', 6, 'Tokyo'),
    (7, 6, '2025-04-01', 30, 'Nagoya'),
    (8, 7, '2025-04-10', 15, 'Tokyo'),
    (9, 2, '2025-05-01', 25, 'Osaka'),
    (10, 8, '2025-05-05', 10, 'Nagoya');

-- Step 4: Snowflake Intelligence オブジェクトの作成
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Step 5: USAGE権限の付与（全ユーザーがアクセス可能にする）
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Step 6: Semantic View の作成（Cortex Analyst 用）
GRANT CREATE SEMANTIC VIEW ON SCHEMA INTELLIGENCE_DEMO_DB.DEMO TO ROLE ACCOUNTADMIN;

CREATE OR REPLACE SEMANTIC VIEW INTELLIGENCE_DEMO_DB.DEMO.SALES_ANALYSIS

  TABLES (
    products AS INTELLIGENCE_DEMO_DB.DEMO.PRODUCTS
      PRIMARY KEY (PRODUCT_ID)
      COMMENT = '商品マスタ',
    sales AS INTELLIGENCE_DEMO_DB.DEMO.SALES
      PRIMARY KEY (SALE_ID)
      COMMENT = '売上トランザクション'
  )

  RELATIONSHIPS (
    sales_to_products AS
      sales (PRODUCT_ID) REFERENCES products
  )

  FACTS (
    sales.revenue AS sales.QUANTITY * products.PRICE
      COMMENT = '売上金額（数量×単価）'
  )

  DIMENSIONS (
    products.product_name AS PRODUCT_NAME
      COMMENT = '商品名',
    products.category AS CATEGORY
      COMMENT = '商品カテゴリ',
    products.price AS PRICE
      COMMENT = '単価',
    sales.sale_date AS SALE_DATE
      COMMENT = '販売日',
    sales.sale_month AS DATE_TRUNC('month', SALE_DATE)
      COMMENT = '販売月',
    sales.region AS REGION
      COMMENT = '販売地域',
    sales.quantity AS QUANTITY
      COMMENT = '販売数量'
  )

  METRICS (
    sales.total_revenue AS SUM(sales.revenue)
      COMMENT = '合計売上金額',
    sales.total_quantity AS SUM(QUANTITY)
      COMMENT = '合計販売数量',
    sales.order_count AS COUNT(SALE_ID)
      COMMENT = '取引件数',
    sales.avg_quantity AS AVG(QUANTITY)
      COMMENT = '平均販売数量'
  )

  COMMENT = '商品と売上データの分析用セマンティックビュー';

-- Step 7: Agent の作成（Semantic View をツールとして接続）
CREATE OR REPLACE AGENT INTELLIGENCE_DEMO_DB.DEMO.SALES_AGENT
  COMMENT = '売上分析エージェント'
  PROFILE = '{"display_name": "Sales Agent", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: "日本語で回答してください。データに基づいて正確に回答し、チャートで可視化できる場合は積極的にチャートを生成してください。"
    orchestration: "売上や商品に関する質問にはCortex Analystツールを使用してください。"
    sample_questions:
      - question: "カテゴリ別の売上合計は？"
      - question: "月別の売上推移を見せて"
      - question: "一番売れた商品は？"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "SalesAnalytics"
        description: "商品と売上データを分析します。商品名、カテゴリ、価格、販売日、地域、数量、売上金額に関する質問に回答できます。"

  tool_resources:
    SalesAnalytics:
      semantic_view: "INTELLIGENCE_DEMO_DB.DEMO.SALES_ANALYSIS"
  $$;

-- Step 8: Agent を Snowflake Intelligence に追加
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT INTELLIGENCE_DEMO_DB.DEMO.SALES_AGENT;

----------------------------------------------------------------------
-- セットアップ完了！
-- https://ai.snowflake.com にアクセスして SALES_AGENT を選択し、
-- 「カテゴリ別の売上合計は？」などと質問してみてください。
----------------------------------------------------------------------

----------------------------------------------------------------------
-- クリーンアップ（デモ環境を削除する場合にコメントを外して実行）
----------------------------------------------------------------------
-- DROP AGENT IF EXISTS INTELLIGENCE_DEMO_DB.DEMO.SALES_AGENT;
-- DROP SEMANTIC VIEW IF EXISTS INTELLIGENCE_DEMO_DB.DEMO.SALES_ANALYSIS;
-- DROP SNOWFLAKE INTELLIGENCE IF EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
-- DROP DATABASE IF EXISTS INTELLIGENCE_DEMO_DB;
