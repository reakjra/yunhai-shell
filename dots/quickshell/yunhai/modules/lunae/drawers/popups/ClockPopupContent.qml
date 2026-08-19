import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.bar

Column {
    spacing: 6

    StyledPopupHeaderRow {
        icon: "calendar_month"
        label: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy")
    }

    StyledPopupValueRow {
        icon: "timelapse"
        label: Translation.tr("System uptime:")
        value: DateTime.uptime
    }

    StyledPopupValueRow {
        icon: "checklist"
        label: Translation.tr("To Do:")
        value: ""
    }

    StyledText {
        width: parent.width
        wrapMode: Text.Wrap
        color: Appearance.colors.colOnSurfaceVariant
        text: {
            const unfinished = Todo.list.filter(item => !item.done)
            if (unfinished.length === 0)
                return Translation.tr("No pending tasks")
            const limited = unfinished.slice(0, 5)
            let t = limited.map((item, i) => `  ${i + 1}. ${item.content}`).join('\n')
            if (unfinished.length > 5)
                t += `\n  ${Translation.tr("... and %1 more").arg(unfinished.length - 5)}`
            return t
        }
    }
}
