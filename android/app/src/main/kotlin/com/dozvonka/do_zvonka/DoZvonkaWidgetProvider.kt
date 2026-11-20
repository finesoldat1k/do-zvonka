package com.dozvonka.do_zvonka

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class DoZvonkaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs: SharedPreferences = context.getSharedPreferences("do_zvonka_widget", Context.MODE_PRIVATE)

        val remainingText = prefs.getString("remaining_text", "осталось 00:00") ?: "осталось 00:00"
        val periodType = prefs.getString("period_type", "урок") ?: "урок"

        val views = RemoteViews(context.packageName, R.layout.do_zvonka_widget)
        views.setTextViewText(R.id.widget_text, remainingText)
        views.setTextViewText(R.id.widget_period, periodType)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    companion object {
        fun updateWidgetFromFlutter(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, DoZvonkaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            for (appWidgetId in appWidgetIds) {
                val provider = DoZvonkaWidgetProvider()
                provider.updateWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}