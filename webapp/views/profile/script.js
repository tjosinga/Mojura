var ProfileView = (function ($) {

    function editProfile() {
        $(".btn-primary", "#modal-edit-profile").button("loading");
        values = {};
        $.each($("form", "#modal-edit-profile").serializeArray(), function (index, data) {
            values[data.name] = data.value;
        });

        options = {
            success: function () {
                $("span[data-key=fullname]").html(values["firstname"] + " " + values["infix"] + " " + values["lastname"]);
                $("div[data-key=email]").attr("data-value", values["email"]).html("<a href='mailto:" + values["email"] + "'>" + values["email"] + "</a>");
                $("#modal-edit-profile").modal("hide");
                $(".btn-primary", "#modal-edit-profile").button("reset");
            }
        };
        $("form", "#modal-edit-profile").ajaxSubmit(options);
    };

    function editPassword() {
        username = $("div[data-key=username]").attr("data-value");
        realm = $("input[name=realm]").val();
        old_password = $("input[name=password_old]").val();
        new_password = $("input[name=password_new]").val();
        password_check = $("input[name=password_check]").val();
        old_digest = CryptoJS.MD5(username + ":" + realm + ":" + old_password).toString();
        new_digest = CryptoJS.MD5(username + ":" + realm + ":" + new_password).toString();

        url = $("#modal-edit-password").find("form").attr("action");
        data = "new_password=" + new_digest;
        if (old_password !== undefined)
            data += "&old_password=" + old_digest;
        $.post(url, data, function (json) {
            $("#modal-edit-password").modal("hide");
            $(".btn-primary", "#modal-edit-password").button("reset");
        });
    };

    return {
        editProfile: editProfile,
        editPassword: editPassword
    };

})(jQuery);