OwlKnowledge 企画書

1. 概要

OwlKnowledge は、プロジェクトに関係する議事録、論文、調査結果、参考資料、実験結果などを集約し、AIが意思決定に利用しやすい知識構造へ継続的に整理するための基盤である。

Owlspecが、

«決定された正本»

を管理するのに対し、OwlKnowledgeは、

«正しい決定を行うための材料»

を管理する。

OwlKnowledge内の情報は必ずしも正しい必要はない。

矛盾する論文や意見、古い情報、未検証の仮説も保持できる。

---

2. 解決する問題

プロジェクトでは次のような情報が大量に存在する。

- 議事録
- 論文
- Web記事
- 技術調査
- ベンチマーク
- 実験結果
- ADR候補
- 比較資料
- チャットログ
- 外部仕様

通常はファイルやフォルダ単位で分散しており、

«必要な情報は存在するが、情報同士の関係が分からない»

状態になりやすい。

単純な全文検索やベクトル検索では、

- この論文は何を支持しているか
- どの実験がこの仮説を否定したか
- この議論はどの設計案につながったか
- 同じ問題について別資料が何を主張しているか

まで扱いにくい。

---

3. 基本思想

OwlKnowledgeでは、

«Sourceが正本、Knowledge GraphはAIによる理解»

とする。

Sources
   ↓
   解析
      ↓
      Knowledge Graph

      Sourceには、

      Markdown
      PDF
      論文
      議事録
      URL
      実験結果
      コード

      などを利用できる。

      Knowledge Graphは自由に変更・再構築できる。

      ---

      4. Knowledge Graph

      例えば、

      Paper A
       ├─ supports ─────→ Hypothesis X
        ├─ uses ─────────→ Method Y
         └─ contradicts ──→ Paper B

         Experiment C
          └─ evaluates ────→ Hypothesis X

          Meeting D
           └─ discusses ────→ Design E

           のような関係をAIが生成する。

           重要なのは、最初から巨大な固定Ontologyを設計しないこと。

           Graphの構造は利用を通して成長させる。

           ---

           5. 進化するグラフ構造

           OwlKnowledgeの特徴は、Knowledge Graphの内容だけではなく、

           «どのような構造にすると知識を最も有効に利用できるか»

           自体を改善対象にすることである。

           例えば最初は、

           Document → Topic

           程度だった構造が、利用経験から、

           Document
            ↓
            Claim
             ↓
             Evidence
              ↓
              Experiment
               ↓
               Decision Candidate

               の方が有効だと判断されれば構造を変える。

               ただし変更可能なのは派生グラフであり、Sourceそのものは破壊しない。

               そのため、

               Sources
                 ↓
                 rebuild
                   ↓
                   Graph

                   が常に可能である。

                   ---

                   6. 構造そのものの共有

                   OwlKnowledgeでは、プロジェクト固有Knowledgeを外部へ共有しなくても、

                   «有効だったKnowledge構造»

                   だけを共有できる可能性がある。

                   例えば研究プロジェクトで、

                   Paper
                    → Claim
                     → Method
                      → Experiment
                       → Evidence

                       という構造が有効だった場合、

                       Source内容を含めずに構造や関係定義のみを他プロジェクトへ転用する。

                       さらに複数プロジェクトの利用結果から、

                       Structure v1
                        ↓
                        Project A
                         ↓
                         改善
                          ↓
                          Structure v2
                           ↓
                           Project B / C
                            ↓
                            改善

                            と進化させられる。

                            将来的にはコミュニティが改善した構造をPRで取り込み、初期構造そのものを成長させることも可能とする。

                            ---

                            7. 固定Ontologyにはしない

                            完全自由なGraphも、完全固定のOntologyも避ける。

                            初期状態では少数の一般的な関係だけ提供する。

                            例：

                            references
                            supports
                            contradicts
                            derived-from
                            related-to
                            evaluates

                            必要な構造はAIがSourceと利用状況を見ながら拡張する。

                            重要なのは、

                            «Schemaを増やすことではなく、検索・理解・意思決定が改善されたか»

                            で構造変更を評価すること。

                            ---

                            8. Owlspecとの違い

                            例として、

                            Paper A:
                            SQLiteで十分

                            Experiment B:
                            PostgreSQLの方が高速

                            Meeting C:
                            運用コストを優先したい

                            これらはOwlKnowledgeに置く。

                            最終的に、

                            このプロジェクトではSQLiteを使用する

                            と決定した場合のみOwlspecの対象になる。

                            したがって、

                            OwlKnowledge
                            「判断材料」

                            Owlspec
                            「判断結果」

                            という明確な境界を持つ。

                            ---

                            9. OwlGrowthとの違い

                            OwlKnowledge：

                            «世界・プロジェクトについて何を知っているか»

                            OwlGrowth：

                            «経験からAI自身がどう行動を変えるか»

                            例えば、

                            「PostgreSQLの接続プールにはこの制約がある」

                            はOwlKnowledge。

                            「DB障害調査では最初にpool saturationを確認する」

                            という経験から得た行動改善はOwlGrowth。

                            両者は概念上分離する。

                            ---

                            10. 他Owlツールへの非依存

                            OwlKnowledge自身はOwlspecやOwlGrowthを認知しない。

                            専用Integration APIも基本的には設けない。

                            例えばKnowledgeのSourceとして、

                            ./docs/foo.md
                            ./experiments/result.json
                            ./spec/design.md
                            https://example.com/paper

                            を参照するだけでよい。

                            そのファイルが別のOwlツール管理下にあるかどうかはOwlKnowledgeの責務外とする。

                            AIが必要に応じて意味的に横断利用する。

                            ---

                            11. 実装方針

                            OwlGrowthと同様、

                            «AI CLIネイティブ機能だけでどこまで実現可能か»

                            を最初に検証する。

                            APMによってSkillとして導入できることを前提とする。

                            初期構成例：

                            .owlknowledge/
                            ├── sources.jsonl
                            ├── nodes.jsonl
                            └── edges.jsonl

                            またはさらに単純化し、

                            .owlknowledge/
                            ├── sources/
                            └── graph.json

                            から開始してもよい。

                            AI自身が通常のファイル操作だけで更新できる状態を優先する。

                            補助処理が必要な場合のみbash + jq等を導入する。

                            ---

                            12. 検索

                            OwlKnowledgeは巨大な独自検索エンジンを最初から作らない。

                            最初はAI CLIが持つ、

                            - grep / ripgrep
                            - ファイル検索
                            - Agent context
                            - native tools

                            を利用する。

                            データ量が増加し、明確に限界が確認されてから、

                            - SQLite
                            - FTS
                            - Embedding
                            - Graph DB

                            などの導入を検討する。

                            技術を先に入れない。

                            ---

                            13. 設計原則

                            1. Sourceを正本とする
                            2. Graphを派生物とする
                            3. Knowledgeは真実である必要がない
                            4. 矛盾するSourceも保持する
                            5. Graph構造そのものを改善可能にする
                            6. 固定Ontologyを肥大化させない
                            7. Structureを内容から分離して共有可能にする
                            8. 他Owlツールへ依存しない
                            9. AI CLIネイティブ機能を優先する
                            10. 検索技術やDBを必要になるまで導入しない

                            14. 成功条件

                            OwlKnowledgeの価値はGraphの大きさではなく、

                            - 必要なSourceへ到達しやすくなる
                            - 関連資料をAIが正しく発見できる
                            - 矛盾する主張を発見できる
                            - 根拠を辿れる
                            - 新しいSource追加後に既存理解が適切に更新される
                            - Graph構造の改善によって意思決定支援が向上する

                            ことで評価する。

                            最終的には、

                            «資料が増えるほど混乱するのではなく、プロジェクトの理解構造そのものが成長する»

                            状態を目指す。
