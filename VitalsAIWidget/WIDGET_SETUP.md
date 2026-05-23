# Adding the Widget Target in Xcode

## Steps

1. **Add the target**
   - Xcode → File → New → Target → Widget Extension
   - Product Name: `VitalsAIWidget`
   - Uncheck "Include Configuration App Intent"
   - Click Finish

2. **Replace the generated files**
   - Delete the auto-generated Swift files Xcode added
   - Add `VitalsAIWidget.swift` and `VitalsAIWidgetBundle.swift` from this folder to the new target

3. **Add App Group capability to BOTH targets**
   - Select the `VitalsAI` app target → Signing & Capabilities → + Capability → App Groups
   - Add group: `group.com.saisuryasambangi.VitalsAI`
   - Repeat for the `VitalsAIWidget` target

4. **Update AppModelContainer to use the shared App Group store**
   In `Core/AppModelContainer.swift`, replace the `ModelConfiguration` with:
   ```swift
   let groupURL = FileManager.default.containerURL(
       forSecurityApplicationGroupIdentifier: "group.com.saisuryasambangi.VitalsAI"
   )!
   let storeURL = groupURL.appendingPathComponent("VitalsAI.store")
   let config = ModelConfiguration(schema: schema, url: storeURL)
   ```

5. **Add InsightRecord to the widget target**
   - In the Project Navigator, select `Core/Models/InsightRecord.swift`
   - In the File Inspector (right panel), check the box for `VitalsAIWidget` under Target Membership

6. **Build and run** — add the widget to your home screen via long-press → Edit → +
