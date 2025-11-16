using System.Collections.Generic;
using System.Linq;
using nadena.dev.ndmf;
using TexColAdjuster.Runtime;
using UnityEngine;

namespace TexColAdjuster.Editor.NDMF
{
    public class TextureAdjustmentPass : Pass<TextureAdjustmentPass>
    {
        protected override void Execute(BuildContext context)
        {
            var components = context.AvatarRootObject.GetComponentsInChildren<TextureColorAdjustmentComponent>(true);

            foreach (var component in components)
            {
                if (!component.applyDuringBuild)
                    continue;

                ProcessComponent(context, component);
            }
        }

        private void ProcessComponent(BuildContext context, TextureColorAdjustmentComponent component)
        {
            if (component.referenceTexture == null)
            {
                Debug.LogWarning($"[TexColAdjuster] Skipping component on '{component.gameObject.name}': Missing referenceTexture");
                return;
            }

            var bindings = component.EnumerateValidBindings().ToList();
            if (bindings.Count == 0)
            {
                Debug.LogWarning($"[TexColAdjuster] Skipping component on '{component.gameObject.name}': No valid renderer bindings");
                return;
            }

            var processedTextures = new Dictionary<Texture2D, Texture2D>();
            int updatedBindings = 0;

            foreach (var binding in bindings)
            {
                var renderer = binding.renderer;
                if (renderer == null)
                {
                    Debug.LogWarning($"[TexColAdjuster] Binding on '{component.gameObject.name}' references a missing renderer. Skipping.");
                    continue;
                }

                var materials = renderer.sharedMaterials;
                if (materials == null)
                {
                    Debug.LogWarning($"[TexColAdjuster] Renderer '{renderer.name}' has no shared materials. Skipping binding.");
                    continue;
                }

                int slot = binding.materialSlot;
                if (slot < 0 || slot >= materials.Length)
                {
                    Debug.LogWarning($"[TexColAdjuster] Material slot {slot} is out of range for renderer '{renderer.name}'. Skipping binding.");
                    continue;
                }

                var targetMaterial = materials[slot];
                if (targetMaterial == null)
                {
                    Debug.LogWarning($"[TexColAdjuster] Material slot {slot} on renderer '{renderer.name}' is null. Skipping binding.");
                    continue;
                }

                var originalTexture = targetMaterial.GetTexture("_MainTex") as Texture2D;
                if (originalTexture == null)
                {
                    Debug.LogWarning($"[TexColAdjuster] Renderer '{renderer.name}' material '{targetMaterial.name}' has no _MainTex. Skipping binding.");
                    continue;
                }

                if (!processedTextures.TryGetValue(originalTexture, out var adjustedTexture))
                {
                    adjustedTexture = ProcessTexture(component, originalTexture);

                    if (adjustedTexture == null)
                    {
                        Debug.LogError($"[TexColAdjuster] Failed to process texture '{originalTexture.name}' for component '{component.gameObject.name}'");
                        continue;
                    }

                    processedTextures.Add(originalTexture, adjustedTexture);
                }

                var clonedMaterial = Object.Instantiate(targetMaterial);
                clonedMaterial.name = targetMaterial.name + " (TexColorAdjusted)";
                clonedMaterial.SetTexture("_MainTex", adjustedTexture);

                materials[slot] = clonedMaterial;
                renderer.sharedMaterials = materials;
                updatedBindings++;
            }

            if (updatedBindings > 0)
            {
                Debug.Log($"[TexColAdjuster] Processed texture adjustments for {updatedBindings} binding(s) on '{component.gameObject.name}'.");
            }
        }

        private Texture2D ProcessTexture(TextureColorAdjustmentComponent component, Texture2D originalTexture)
        {
            TextureImportBackup originalBackup = null;
            Texture2D readableReference = null;
            try
            {
                // Ensure the texture is readable and backup settings
                var readableTexture = TextureProcessor.MakeTextureReadable(originalTexture, out originalBackup);
                if (readableTexture == null)
                {
                    Debug.LogError($"[TexColorAdjuster] Failed to make texture readable: {originalTexture?.name ?? "null"}");
                    return null;
                }

                // Use non-destructive copy for reference texture to avoid modifying import settings
                readableReference = TextureProcessor.MakeReadableCopy(component.referenceTexture);
                if (readableReference == null)
                {
                    Debug.LogError($"[TexColorAdjuster] Failed to create readable copy of reference texture: {component.referenceTexture?.name ?? "null"}");
                    return null;
                }

                Texture2D result;
                if (component.useHighPrecisionMode)
                {
                    // High precision mode processing
                    var highPrecisionConfig = new HighPrecisionProcessor.HighPrecisionConfig
                    {
                        referenceGameObject = component.highPrecisionReferenceObject,
                        materialIndex = component.highPrecisionMaterialIndex,
                        uvChannel = component.highPrecisionUVChannel,
                        dominantColorCount = component.highPrecisionDominantColorCount,
                        useWeightedSampling = component.highPrecisionUseWeightedSampling,
                        maskTexture = component.highPrecisionMaskTexture,
                        maskThreshold = component.highPrecisionMaskThreshold
                    };

                    if (!HighPrecisionProcessor.ValidateHighPrecisionConfig(highPrecisionConfig, readableReference))
                    {
                        Debug.LogWarning($"[TexColorAdjuster] High precision mode is enabled but configuration is invalid. Falling back to standard processing.");
                        result = ColorAdjuster.AdjustColors(
                            readableTexture,
                            readableReference,
                            component.intensity,
                            component.preserveLuminance,
                            component.adjustmentMode
                        );
                        // Apply post-adjustment parameters (hue, saturation, brightness, gamma)
                        if (result != null)
                        {
                            try
                            {
                                Color[] pixels = TextureUtils.GetPixelsSafe(result);
                                if (pixels != null)
                                {
                                    var adjusted = TexColAdjuster.Editor.ColorSpaceConverter.ApplyHSBGToArray(
                                        pixels,
                                        component.hueShift,
                                        component.saturation,
                                        component.brightness,
                                        component.gamma
                                    );
                                    TextureUtils.SetPixelsSafe(result, adjusted);
                                }
                            }
                            catch (System.Exception ex)
                            {
                                Debug.LogError($"[TexColorAdjuster] Failed to apply post-adjustments: {ex.Message}");
                            }
                        }
                    }
                    else
                    {
                        result = HighPrecisionProcessor.ProcessWithHighPrecision(
                            readableTexture,
                            readableReference,
                            highPrecisionConfig,
                            component.intensity * 100f, // Convert back to 0-100 range for processor
                            component.preserveLuminance,
                            component.adjustmentMode
                        );
                    }
                }
                else if (component.useDualColorSelection)
                {
                    result = ColorAdjuster.AdjustColorsWithDualSelection(
                        readableTexture,
                        readableReference,
                        component.targetColor,
                        component.referenceColor,
                        component.intensity,
                        component.preserveLuminance,
                        component.adjustmentMode,
                        component.selectionRange
                    );
                }
                else
                {
                    result = ColorAdjuster.AdjustColors(
                        readableTexture,
                        readableReference,
                        component.intensity,
                        component.preserveLuminance,
                        component.adjustmentMode
                    );
                }

                return result;
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"[TexColorAdjuster] Exception while processing texture: {ex.Message}\n{ex.StackTrace}");
                return null;
            }
            finally
            {
                // Restore original texture import settings (target texture only)
                if (originalBackup != null)
                {
                    originalBackup.RestoreSettings();
                }

                // Clean up temporary reference texture copy
                if (readableReference != null && readableReference != component.referenceTexture)
                {
                    UnityEngine.Object.DestroyImmediate(readableReference);
                }
            }
        }
    }
}
