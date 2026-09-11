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
	implicitWidth:  item ? item.implicitWidth  : 0
	implicitHeight: item ? item.implicitHeight : 0

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

