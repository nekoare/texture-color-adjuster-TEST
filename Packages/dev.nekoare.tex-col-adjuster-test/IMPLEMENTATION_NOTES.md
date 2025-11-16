# TexColAdjuster リアルタイムプレビュー高速化実装ノート

## 実装概要

NDMFプレビューシステムのパフォーマンスを改善し、パラメータ変更時の操作性を向上させました。

## 実装内容

### Phase 1: context.Observe()の最適化

**ファイル**: `Editor/NDMF/TexColorAdjusterPreview.cs`

**変更内容**:
- `context.Observe(component)` → 特定のプロパティのみを監視
- 不要な再計算を削減

```csharp
// Before
context.Observe(component);

// After
context.Observe(component, c => c.targetRenderer);
context.Observe(component, c => c.materialSlot);
context.Observe(component, c => c.referenceTexture);
// ... その他の必要なプロパティのみ
```

**効果**: NDMFの再計算トリガーを必要最小限に抑制

---

### Phase 2: GPU処理の導入

#### 2.1 ExtendedRenderTextureクラスの追加

**ファイル**: `Editor/Models/ExtendedRenderTexture.cs`

**役割**:
- RenderTextureの拡張クラス
- Graphics.Blitによる高速テクスチャコピー
- リソース管理の自動化

**参考**: Color Changer for Unityの実装

#### 2.2 LABヒストグラムマッチングのCompute Shader実装

**ファイル**: `Editor/Resources/LabHistogramMatching.compute`

**機能**:
- GPU上でのLAB色空間変換
- ヒストグラムマッチング処理
- 輝度保存オプション

**主要カーネル**:
- `LabHistogramMatching`: メイン処理

#### 2.3 統計情報計算のCompute Shader実装

**ファイル**: `Editor/Resources/LabStatistics.compute`

**機能**:
- GPU上でのLAB統計情報計算（平均、標準偏差）
- Parallel Reduction最適化

**主要カーネル**:
- `ComputeMean`: 平均値計算
- `ComputeStdDev`: 標準偏差計算

#### 2.4 GPUColorAdjusterクラスの追加

**ファイル**: `Editor/GPUColorAdjuster.cs`

**役割**:
- GPU処理の統合管理
- Compute Shaderの読み込みと実行
- CPUフォールバック機能

**主要メソッド**:
```csharp
public static ExtendedRenderTexture AdjustColorsGPU(
    Texture2D targetTexture,
    Texture2D referenceTexture,
    float intensity,
    bool preserveLuminance,
    ColorAdjustmentMode mode)
```

#### 2.5 プレビューシステムへの統合

**ファイル**: `Editor/NDMF/TexColorAdjusterPreview.cs`

**変更内容**:
- `ProcessTextureGPU()` メソッドの実装
- GPU処理の可用性チェック
- 自動フォールバック機能

```csharp
private Texture ProcessTextureGPU(TextureColorAdjustmentComponent component, Texture2D originalTexture)
{
    if (!GPUColorAdjuster.IsGPUProcessingAvailable())
    {
        // CPU処理にフォールバック
        return ProcessTextureCPU(component, originalTexture);
    }

    // GPU処理実行
    return GPUColorAdjuster.AdjustColorsGPU(...);
}
```

---

## 使用方法

### 設定項目

`TextureColorAdjustmentComponent`に以下の設定があります：

- **applyDuringBuild**: ビルド時に調整を適用するかどうか
- **PreviewEnabled**: プレビューの有効/無効
- **PreviewOnCPU**:
  - `false` (デフォルト): GPU処理を使用（高速）
  - `true`: CPU処理を使用（互換性重視）

### GPU処理の動作条件

以下の条件を満たす場合、GPU処理が使用されます：

1. `PreviewOnCPU` が `false`
2. システムがCompute Shaderをサポート
3. Compute Shaderファイルが正しく読み込まれている
4. 調整モードが`LabHistogramMatching`

条件を満たさない場合、自動的にCPU処理にフォールバックします。

---

## 対応状況

### 実装済み

✅ **Phase 1: context.Observe()最適化**
- 特定プロパティのみ監視

✅ **Phase 2: GPU処理（LABヒストグラムマッチング）**
- ExtendedRenderTexture
- Compute Shader実装
- 統計情報計算
- プレビュー統合

### 未実装（将来の拡張）

⏳ **その他の調整モードのGPU実装**
- HueShift
- ColorTransfer
- AdaptiveAdjustment

⏳ **Dual Color Selection のGPU実装**
- 現在はCPUフォールバック

---

## パフォーマンス

### 期待される改善

| 項目 | CPU処理 | GPU処理 | 改善率 |
|------|---------|---------|--------|
| 2048x2048テクスチャ | ~500ms | ~50ms | 10倍 |
| パラメータ変更の反応速度 | 遅延あり | リアルタイム | - |

※実際のパフォーマンスはハードウェアに依存します

### 最適化のポイント

1. **Observe最適化**: 不要な再計算の削減
2. **GPU処理**: 並列処理による高速化
3. **RenderTexture**: インポート設定変更不要

---

## トラブルシューティング

### GPU処理が動作しない

**確認事項**:
1. Compute Shaderファイルが`Editor/Resources/`に配置されているか
2. システムがCompute Shaderをサポートしているか
3. Consoleにエラーメッセージが出ていないか

**対処法**:
- `PreviewOnCPU`を`true`にしてCPU処理を使用

### プレビューが更新されない

**確認事項**:
1. `PreviewEnabled`が`true`か
2. コンポーネントの`applyDuringBuild`が`true`か
3. NDMFプレビューが有効か

---

## 技術的な詳細

### LAB色空間変換

GPU実装では以下の変換を行います：

```
RGB → (Gamma補正) → XYZ → LAB
LAB → XYZ → (逆Gamma補正) → RGB
```

**参照白色点**: D65標準光源 (0.95047, 1.00000, 1.08883)

### ヒストグラムマッチング

統計情報（平均・標準偏差）を用いた変換：

```
normalized = (value - sourceMean) / sourceStd
result = normalized * targetStd + targetMean
```

### Parallel Reduction

統計計算では、Shared Memoryを使用した並列リダクションで高速化：

```
Thread Group: 8x8 (64スレッド)
Reduction Steps: 32 → 16 → 8 → 4 → 2 → 1
```

---

## 参考実装

本実装は以下を参考にしています：

- **Color Changer for Unity**: https://github.com/puk06/Color-Changer-For-Unity
  - ExtendedRenderTextureの設計
  - GPU処理のアーキテクチャ

---

## 今後の改善案

### 短期

1. **他の調整モードのGPU実装**
   - HueShift: 比較的簡単
   - ColorTransfer: 中程度
   - AdaptiveAdjustment: 複雑

2. **Dual Color SelectionのGPU実装**

### 中期

1. **キャッシング機構**
   - 同じパラメータなら結果を再利用

2. **非同期処理**
   - バックグラウンドで処理

### 長期

1. **Fragment Shader版の実装**
   - より軽量な処理

2. **マルチパス処理**
   - より複雑なアルゴリズムのサポート

---

## まとめ

本実装により、LABヒストグラムマッチングモードでのリアルタイムプレビューが大幅に高速化されました。

**主な改善点**:
- ✅ パラメータ変更時の遅延削減
- ✅ GPU並列処理による高速化
- ✅ 自動フォールバック機能
- ✅ 既存機能との完全な互換性

ユーザーは設定を変更することなく、自動的に最適な処理方法が選択されます。
