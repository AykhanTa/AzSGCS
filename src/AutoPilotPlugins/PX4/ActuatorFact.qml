import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls


Loader {
	property var fact
	id:                     loader

	// Loader daxildəki elementin ölçüsünü layout-a ötürsün — əks halda combo
	// çox dar render olunub (PWM/DShot) yazıları oxunmurdu.
	//
	// Qt 6.11 marked QQuickImplicitSizeItem::implicitWidth/implicitHeight as OVERRIDE,
	// which finally makes the read-only redeclaration shadow the writable QQuickItem
	// ones -- assigning them here is a hard error now. Every use site is inside a
	// Layout, so drive the layout directly instead; that is what it reads anyway.
	Layout.preferredWidth:  item ? item.implicitWidth  : 0
	Layout.preferredHeight: item ? item.implicitHeight : 0

	Component {
		id: factComboBox
		FactComboBox {
			fact:           loader.fact
			indexModel:     false
			sizeToContents: true
			// Qısa dəyərlərdə (PWM) belə rahat oxunsun deyə minimum en
			implicitWidth:  Math.max(ScreenTools.defaultFontPixelWidth * 12,
			                         contentItem.implicitWidth + leftPadding + rightPadding + padding
			                         + ScreenTools.defaultFontPixelWidth)
		}
	}
	Component {
		id: factCheckbox
		FactCheckBox {
			fact:           loader.fact
		}
	}

	Component {
		id: factTextField
		FactTextField {
			fact:           loader.fact
			width:          ScreenTools.defaultFontPixelWidth * 8
			showUnits:      false
		}
	}
	Component {
		id: factReadOnly
		QGCLabel {
			text:           loader.fact.valueString
		}
	}
	Component {
		id: notAvailable
		QGCLabel {
			text:           qsTr("(Param not available)")
			font.pointSize: 7

		}
	}
	sourceComponent: fact ? 
		(fact.enumStrings.length > 0 ? factComboBox : 
			(fact.readOnly ? factReadOnly : (fact.typeIsBool ? factCheckbox : factTextField))
		) : notAvailable
}

