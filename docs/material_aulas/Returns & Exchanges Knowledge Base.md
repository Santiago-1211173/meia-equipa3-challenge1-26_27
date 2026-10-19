# Returns and Exchanges Knowledge Base

**Proposal 1  |  US & CAN Version 1.3**

**Purpose:** Provide concise decision rules for evaluating returns, exchanges, price adjustments, refund tender, approvals, and product disposition across Mainline, Outlet, levi.com, levi.ca, and BackPocket transactions.

**Source basis:** Returns and Exchanges Policy, customer receipt language, and confirmed operating decisions.

**Rule outcomes:** ALLOW means process under the standard rule. DENY means do not process. REVIEW means management judgment or approval is required. ROUTE means use a separate required process.

## Decision Sequence

| Step | Decision | Required input |
| --- | --- | --- |
| 1 | Identify market and store type | United States or Canada; Mainline or Outlet. |
| 2 | Identify purchase channel | Store, Outlet, levi.com, levi.ca, BackPocket, Canadian franchise, wholesale, or unknown. |
| 3 | Confirm product eligibility | Check brand, POS SKU, customization or alteration, and product condition. |
| 4 | Verify proof of purchase | Verified receipt or order record versus blind return. |
| 5 | Apply timeframe | Within 30 days, after 30 days, or 14-day price adjustment. |
| 6 | Determine transaction outcome | Refund, exchange, exact-item swap, store credit, price adjustment, denial, or escalation. |
| 7 | Determine value and tender | Original paid value, current selling price, promotional value, and permitted refund method. |
| 8 | Complete controls | Approval, signatures, media retention, attribution, product handling, and fraud reporting. |


## Required Inputs

| Rule ID | Input | Allowed values |
| --- | --- | --- |
| IN-001 | Market | United States or Canada |
| IN-002 | Store type | Mainline or Outlet |
| IN-003 | Purchase channel | Mainline, Outlet, levi.com, levi.ca, BackPocket, Canadian franchise, wholesale, or unknown |
| IN-004 | Proof | Printed receipt, digital receipt, order confirmation, gift receipt, transaction lookup, receipt photo, BackPocket order lookup, or none |
| IN-005 | Request | Return, exchange, exact-item swap, gift return, or price adjustment |
| IN-006 | Timing | Days since purchase or shipment |
| IN-007 | Product | Brand, SKU, customization or alteration, bodywear status, and current assortment status |
| IN-008 | Condition | Unworn, tags attached or detached, no tags, worn, washed, defective, soiled, contaminated, or unsafe |
| IN-009 | Original tender | Cash, gift card, credit, debit, contactless, PayPal, Venmo, Afterpay, or Interac |
| IN-010 | Sellability | Can be verified, retagged when permitted, and safely resold |


## Hard Stop Rules

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| HS-001 | Product does not ring in the POS system of record | DENY return and exchange. | A valid product SKU is required. |
| HS-002 | Product is Dockers, Levi Strauss Signature, Beyond Yoga, or a wholesale product not carried in the store | DENY return and exchange. | Levi's retail stores do not accept these products. |
| HS-003 | Product was customized, altered, or hemmed | DENY return and exchange. | Customized or altered product is not returnable, including otherwise defective product. |
| HS-004 | A different or generic SKU would be required | DENY the transaction. | The specific product SKU must be used. Follow the separate Canada franchise process where applicable. |
| HS-005 | Afterpay online return requests an exchange, gift card, cash, or other tender exception | DENY the exception; refund through Afterpay to the original payment method. | Afterpay tender exceptions are prohibited. |
| HS-006 | Employee is not authorized to process returns or exchanges | ROUTE to Store Management, Key Holder, or a District Manager-approved Lead Cashier or Elevated Stylist. | Only authorized employees may process the transaction. |


## Product Condition Rules

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| PC-001 | Unworn, original condition, original tags attached | ALLOW if all channel, proof, and timing rules are met. | Standard eligible condition. |
| PC-002 | Unworn with detached tags presented | REVIEW. Approve only when the item can be verified, correctly retagged, and resold. | Sellability is a formal exception factor. |
| PC-003 | Unworn with no tags | REVIEW. Approve only when the item can be verified and prepared for resale. Otherwise DENY. | An item that cannot be retagged or resold should not be accepted. |
| PC-004 | Clearly worn with no confirmed damage or defect | DENY refund. Management may approve an exact-item exchange only; do not issue cash or unrestricted store credit. | Worn merchandise is not eligible for a standard return. |
| PC-005 | Washed with no confirmed manufacturing defect | DENY return and exchange. | Washed product is non-sellable. |
| PC-006 | Confirmed manufacturing defect and product is not customized or altered | ALLOW refund to permitted tender or replace with a non-defective item. Damage out the returned item. | Manufacturing defects are eligible for resolution. |
| PC-007 | Bodywear in any condition | ALLOW the return, then determine resale, markdown, damage-out, or biohazard disposition. | Bodywear must be accepted regardless of condition. |
| PC-008 | Item is soiled, contaminated, or unsafe to handle | Minimize handling; place in a biohazard bag; label and date; secure in the back room; email the designated corporate office; do not resell; await disposal direction. | Protect employees and isolate unsafe product. |


## Proof and Timeframe Rules

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| PT-001 | Printed receipt, digital receipt, order confirmation, gift receipt, transaction lookup, receipt photo, or BackPocket order lookup verifies the purchase | Treat as a verified return. | These records qualify as proof of purchase. |
| PT-002 | No purchase can be verified | Process only as a blind return if the product is otherwise eligible. | Blind-return value and tender rules apply. |
| PT-003 | Verified eligible item is returned within 30 days | ALLOW full refund of the amount paid to the original tender, or an eligible exchange. | Standard return window. |
| PT-004 | Verified eligible item is returned after 30 days | REVIEW. Store credit may be approved when the item is sellable, verifiable, and low risk. Otherwise DENY. | Late returns are not automatically entitled to a refund. |
| PT-005 | No-receipt item is otherwise eligible | ALLOW exchange or store credit only at the current selling price. | Cash or original-tender refund is not available without proof. |
| PT-006 | No-receipt consumer declines personal information or a language barrier exists | Select Skip and continue the eligible blind return. | Do not pressure the consumer to provide information. |
| PT-007 | In-store purchase requests a price adjustment within 14 days with the original receipt | ALLOW one price adjustment for the identical item using the POS-calculated difference. | Store purchases have a one-time 14-day price adjustment. |
| PT-008 | Price-adjustment request is after 14 days or lacks an original receipt | DENY the price adjustment. | Required timeframe or proof is missing. |


## Channel and Store Type Rules

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| CH-001 | Mainline or Outlet purchase is returned to a Levi's retail store | Apply verified or blind-return rules and the receiving store's valuation rules. | Cross-channel returns are permitted when the product is eligible. |
| CH-002 | levi.com or levi.ca purchase is returned in store and the order is found | ROUTE through BackPocket. Refund to the original tender; U.S. customer may request an e-gift card for another online or BackPocket purchase. | All verified online returns use BackPocket. |
| CH-003 | Online order cannot be found or no receipt is available | Use a blind return only when the policy scenario permits; default tender is gift card. | Blind processing for online returns should be uncommon. |
| CH-004 | Online portal is unavailable | Process the permitted blind return to the original tender. | Portal outage exception. |
| CH-005 | Online order was shipped more than 30 days earlier | Issue gift card when the item is otherwise eligible. | Late online return tender rule. |
| CH-006 | Online customer requests an exchange | Complete the exchange and return any remaining eligible balance to the original tender. | Online exchange balance rule; Afterpay remains excluded. |
| CH-007 | Canada franchise product is presented | ROUTE to the specific Canada franchise return process. Use the franchise SKU procedure; do not substitute a generic SKU. | Canada franchise returns have a separate process. |
| CH-008 | Wholesale product is presented | DENY and direct the customer to the original wholesale retailer. | Levi's stores do not accept wholesale returns. |
| CH-009 | Outlet blind return or exchange | Use current selling price after active Outlet promotions, not MSRP. | Outlet merchandise always has promotional valuation. |
| CH-010 | Receipt-based cross-channel return from Mainline or Online to Outlet | The return may be processed at the original MSRP when permitted by the POS and policy. | Cross-channel Outlet exception. |


## Refund Tender Rules

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| TN-001 | Verified credit or debit card return | Automatically refund the original card through tokenization. Do not ask the customer to present the card. | Original tender is required. |
| TN-002 | Original card is lost or stolen but the bank account remains active | Refund automatically to the original card account. | The token remains linked to the active account. |
| TN-003 | Original card account is closed | Attempt the original card first. Only after decline may the system use a different credit or debit card, cash, or gift card. | Alternate tender is allowed only after the required attempt fails. |
| TN-004 | Debit purchase and the original debit refund has not declined | Do not issue cash; refund the original debit card. | Cash is prohibited for standard debit refunds. |
| TN-005 | Contactless payment such as Apple Pay or Google Pay | Refund automatically to the linked card or bank account. | Refund follows the original account. |
| TN-006 | Partial exchange leaves a refundable balance | Complete the exchange and automatically refund the remaining amount to the original card. | Remaining funds follow the original tender. |
| TN-007 | Gift recipient has the original receipt showing credit or debit tender | Offer tokenized refund to the purchaser's original card or issue store credit. | Gift returns may use store credit. |
| TN-008 | PayPal or Venmo purchase | Require the customer to access the payment app and process the refund through the prescribed app flow. Do not substitute tender outside that process. | PayPal and Venmo are not tokenized. |
| TN-009 | Afterpay in-store purchase | Customer locates the order in the Afterpay app; process the full return to Afterpay and provide the POS return receipt. | The store refunds Afterpay, not the customer's installments. |
| TN-010 | Afterpay online purchase | Process in BackPocket to the original method. Do not provide exchange, gift card, or alternate tender. | Afterpay online tender exceptions are prohibited. |
| TN-011 | Canada Interac standard in-store purchase | Customer must present the same physical Interac card used for the purchase. | Canada Interac cards are not tokenized. |
| TN-012 | Canada BackPocket in-store purchase paid by Interac | Verify Interac; complete the BackPocket return; issue a manual VeriFone refund for the exact amount. Card must be present and may not be keyed. | Manual VeriFone use is limited to this scenario. |


## Exchange and Promotion Rules

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| EP-001 | Receipt-based exchange changes size only | Honor the original sale or promotional price for the replacement item. | Promotion matching is limited to size swaps. |
| EP-002 | Exchange changes style or color | Return the original item at its eligible value and sell the new item at the current price. | It is not a size-only exchange. |
| EP-003 | Blind return occurs under a tier promotion | Use the number of items returned in the current transaction to determine the applicable tier value. | Blind-return value follows the active tier. |
| EP-004 | Receipt-based tier-promotion return | Use the POS-calculated refund based on the original quantity purchased. | The original transaction controls the refund. |
| EP-005 | Cross-channel item is or was in the receiving store's assortment | Reprice to the receiving store's current selling price and return to the sales floor if sellable. | Receiving-store assortment controls resale pricing. |
| EP-006 | Cross-channel item is not in the receiving store's assortment | Place in clearance and mark 20 percent off the returned price; combine with eligible in-store promotions. | Non-assortment cross-channel disposition. |
| EP-007 | Cross-channel item is already on markdown | Place in clearance and apply current eligible markdown promotions. | Markdown merchandise remains clearance. |


## Manager Review and Customer Escalation

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| EX-001 | A standard rule permits manager judgment | Evaluate sellability, proof, time elapsed, transaction value, fraud risk, and customer circumstances. | Sellability is a formal factor in any exception. |
| EX-002 | Customer disputes the standard outcome | Explain the policy and offer the best policy-compliant alternative before considering an exception. | Use compliant options first. |
| EX-003 | Customer becomes angry or creates a disruption | Escalate to the senior leader on duty. Agitation alone does not create eligibility. | The leader evaluates appeasement and store safety. |
| EX-004 | Senior leader considers an appeasement exception | Approve only when no hard stop applies, the item can be verified, fraud risk is low, and the outcome can be completed in the system. | Exceptions cannot bypass absolute controls. |
| EX-005 | Eligible exception item is sellable | Prefer the least expansive resolution: exact-item exchange, then store credit, then original-tender refund when permitted. | Preserve the customer experience while limiting loss. |
| EX-006 | Exception would require prohibited tender, incorrect SKU, excluded product, or bypass of Afterpay, PayPal, Venmo, or online processing | DENY the exception and use the required process. | These controls are not discretionary. |
| EX-007 | Exception is approved | Document reason, approver, amount, outcome, customer concern, and product disposition on the store copy or approved record. | Creates an auditable exception record. |
| EX-008 | Fraud indicators or material inconsistencies exist | Pause the transaction; involve Store Management; report confirmed or significant risk to the District or Area Manager and Global Safety and Security. | Protect against fraud and operational loss. |


## Authorization and Completion Controls

| Rule ID | If | Then | Reason or constraint |
| --- | --- | --- | --- |
| CT-001 | Verified return or exchange | Store Management, Key Holder, or District Manager-approved Lead Cashier or Elevated Stylist may process using their own POS credentials. | Authorized processor requirement. |
| CT-002 | Blind return is processed by an approved Lead Cashier or Elevated Stylist | Obtain XStore Manager approval. | Blind returns require additional approval. |
| CT-003 | Employee logs into the POS | The same employee completes the transaction from start to finish; credentials may not be shared. | Transaction ownership and security. |
| CT-004 | Receipt-based return is completed | Attribute the return to the Stylist credited with the original sale. | Sales attribution requirement. |
| CT-005 | Return or exchange is completed | Obtain customer signature or write Decline; obtain processor signature; obtain witness signature or write SSC for single-store coverage. | Required return receipt controls. |
| CT-006 | Original receipt is surrendered | Staple it to the store copy. If the customer retains it or it includes other items, note that on the store copy. | Media documentation requirement. |
| CT-007 | Transaction record is complete | Retain the store copy and required signatures in media retention files for 90 days. File online return copies with daily media. | Retention requirement. |
| CT-008 | Returned product will be resold | Inspect damage, price tags, and RFID accuracy before returning it to the sales floor. | Only correctly prepared sellable product may return to inventory. |


## Bodywear Disposition

| Rule ID | If | Then |
| --- | --- | --- |
| BW-001 | Original packaging is intact | Inspect fully for signs of wear. Return to sale only when confirmed unworn and sellable. |
| BW-002 | Packaging is missing but product is unworn and the full set is present | Hang in clearance, mark 50 percent off, strike the barcode in red, and apply eligible clearance promotions. |
| BW-003 | Units are missing from the original set or the product was worn | Damage out the entire set. |
| BW-004 | Product is worn and soiled or unsafe | Place immediately in a biohazard bag, label and date, secure in the back room, email the designated corporate office, and follow disposal direction. |


## Expert System Output Fields

| Output ID | Field | Allowed result |
| --- | --- | --- |
| OUT-001 | Eligibility | Allow, deny, review, or route |
| OUT-002 | Transaction type | Refund, exchange, exact-item swap, store credit, price adjustment, or no transaction |
| OUT-003 | Return value | Original paid amount, current selling price, active promotional value, tier value, or POS-calculated value |
| OUT-004 | Refund tender | Original tender, gift card, alternate permitted tender after decline, or required payment application |
| OUT-005 | Approval | None, XStore Manager approval, senior leader approval, or District or Area escalation |
| OUT-006 | Required process | POS, BackPocket, Afterpay app, PayPal or Venmo app flow, VeriFone Interac, Canada franchise process, or damage process |
| OUT-007 | Product disposition | Sales floor, clearance, retag, damage out, biohazard isolation, or return to customer |
| OUT-008 | Documentation | Signatures, exception reason, receipt handling, media retention, and risk reporting |

