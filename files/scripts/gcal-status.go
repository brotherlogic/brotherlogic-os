package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"time"
)

type WaybarOutput struct {
	Text    string `json:"text"`
	Tooltip string `json:"tooltip"`
}

type TimePoint struct {
	DateTime string `json:"dateTime"`
	Date     string `json:"date"`
}

type Event struct {
	Summary string    `json:"summary"`
	Start   TimePoint `json:"start"`
	End     TimePoint `json:"end"`
}

type EventList struct {
	Items []Event `json:"items"`
}

func parseTime(tp TimePoint) (time.Time, bool) {
	if tp.DateTime != "" {
		t, err := time.Parse(time.RFC3339, tp.DateTime)
		return t, err == nil
	}
	if tp.Date != "" {
		t, err := time.Parse("2006-01-02", tp.Date)
		return t, err == nil
	}
	return time.Time{}, false
}

func main() {
	res := WaybarOutput{}
	defer func() {
		out, _ := json.Marshal(res)
		fmt.Println(string(out))
	}()

	_, err := exec.LookPath("gws")
	if err != nil {
		res.Tooltip = "gws (Google Workspace CLI) not found in PATH. Please install it from https://github.com/googleworkspace/cli"
		return
	}

	now := time.Now()
	timeMin := now.Add(-24 * time.Hour).Format(time.RFC3339)
	timeMax := now.Add(24 * time.Hour).Format(time.RFC3339)

	params := fmt.Sprintf(`{"calendarId": "primary", "singleEvents": true, "orderBy": "startTime", "timeMin": "%s", "timeMax": "%s"}`, timeMin, timeMax)
	cmd := exec.Command("gws", "calendar", "events", "list", "--params", params)
	output, err := cmd.Output()
	if err != nil {
		res.Tooltip = fmt.Sprintf("Error running gws: %v. Ensure you are logged in with 'gws login'.", err)
		return
	}

	var list EventList
	if err := json.Unmarshal(output, &list); err != nil {
		res.Tooltip = fmt.Sprintf("Error parsing gws output: %v", err)
		return
	}

	for _, event := range list.Items {
		start, okStart := parseTime(event.Start)
		end, okEnd := parseTime(event.End)

		if okStart && okEnd {
			if (now.After(start) || now.Equal(start)) && now.Before(end) {
				res.Text = fmt.Sprintf(" %s", event.Summary)
				res.Tooltip = fmt.Sprintf("%s\nFrom: %s\nTo: %s", event.Summary, start.Format("15:04"), end.Format("15:04"))
				if event.Start.DateTime == "" {
					res.Tooltip = fmt.Sprintf("%s\nAll day event", event.Summary)
				}
				return
			}
		}
	}
}
